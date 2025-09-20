import Vue from "vue";
import Vuex from "vuex";

import income, { initialIncomeState } from "./stores/income";
import expenses, { initialExpensesState } from "./stores/expenses";
import liabilities, { initialLiabilitiesState } from "./stores/liabilities";
import meta, { initialMetaState } from "./stores/meta";
import assets, { initialAssetsState } from "./stores/assets";
import investments, { initialInvestmentsState } from "./stores/investments";
import fasttrack, { initialFastTrackState } from "./stores/fasttrack";

import {
  listGames,
  createGame,
  getGame,
  updatePlayerSheet,
  getAuditLog,
  endGame,
  getLeaderboard
} from "./api/client";

Vue.use(Vuex);

const clone = value => JSON.parse(JSON.stringify(value));

const sanitizeInvestmentsForSave = state => {
  const investmentsState = clone(state);
  investmentsState.modal = { show: false, type: null, index: -1 };
  return investmentsState;
};

const buildSheetState = rootState => {
  const incomeState = rootState.income ? clone(rootState.income) : initialIncomeState();
  const expensesState = rootState.expenses ? clone(rootState.expenses) : initialExpensesState();
  const liabilitiesState = rootState.liabilities ? clone(rootState.liabilities) : initialLiabilitiesState();
  const assetsState = rootState.assets ? clone(rootState.assets) : initialAssetsState();
  const investmentsState = rootState.investments
    ? sanitizeInvestmentsForSave(rootState.investments)
    : sanitizeInvestmentsForSave(initialInvestmentsState());
  const metaState = rootState.meta ? clone(rootState.meta) : initialMetaState();
  const fastTrackState = rootState.fasttrack ? clone(rootState.fasttrack) : initialFastTrackState();

  return {
    income: incomeState,
    expenses: expensesState,
    liabilities: liabilitiesState,
    assets: assetsState,
    investments: investmentsState,
    meta: metaState,
    fasttrack: fastTrackState
  };
};

const applySheetStateToModules = (commit, sheetState = {}) => {
  commit("income/replaceState", sheetState.income ? clone(sheetState.income) : {}, { root: true });
  commit("expenses/replaceState", sheetState.expenses ? clone(sheetState.expenses) : {}, { root: true });
  commit("liabilities/replaceState", sheetState.liabilities ? clone(sheetState.liabilities) : {}, { root: true });
  commit("assets/replaceState", sheetState.assets ? clone(sheetState.assets) : {}, { root: true });
  const investmentsState = sheetState.investments ? sanitizeInvestmentsForSave(sheetState.investments) : {};
  commit("investments/replaceState", investmentsState, { root: true });
  commit("meta/replaceState", sheetState.meta ? clone(sheetState.meta) : {}, { root: true });
  commit("fasttrack/replaceState", sheetState.fasttrack ? clone(sheetState.fasttrack) : {}, { root: true });
};

const initialRootState = () => ({
  currentView: "load-screen",
  games: [],
  activeGame: null,
  activePlayerId: null,
  auditEntries: [],
  auditPagination: { offset: 0, limit: 50, endReached: false },
  leaderboard: [],
  loading: {
    games: false,
    createGame: false,
    game: false,
    playerSave: false,
    audit: false,
    leaderboard: false
  },
  error: null,
  displaySheet: "Rat Race"
});

export default new Vuex.Store({
  state: initialRootState(),
  getters: {
    passiveIncome: (_state, _getters, rootState) =>
      rootState.income.interest.value +
      rootState.income.interest2.value +
      rootState.investments.realEstate.reduce((sum, it) => sum + (Number(it.income) || 0), 0) +
      rootState.investments.businesses.reduce((sum, it) => sum + (Number(it.income) || 0), 0),
    totalIncome: (_state, getters, rootState) => (Number(rootState.income.salary.value) || 0) + getters.passiveIncome,
    childExpenses: (_state, _getters, rootState) =>
      Number(rootState.expenses.children.numberOfChildren || 0) * Number(rootState.expenses.children.perChildExpense || 0),
    totalExpenses: (_state, getters, rootState, rootGetters) =>
      Number(rootState.expenses.taxes.value) +
      Number(rootState.expenses.mortgage.value) +
      Number(rootState.expenses.schoolLoan.value) +
      Number(rootState.expenses.carLoan.value) +
      Number(rootState.expenses.creditCard.value) +
      Number(rootState.expenses.retail.value) +
      Number(rootState.expenses.other.value) +
      rootGetters["expenses/bankLoanAmount"] +
      getters.childExpenses +
      Number(rootState.expenses.miscellaneousExpense.value),
    cashFlow: (_state, getters) => getters.totalIncome - getters.totalExpenses,
    activeGame: state => state.activeGame,
    activePlayer: (state, getters) => {
      const game = getters.activeGame;
      if (!game || !state.activePlayerId) return null;
      return game.players?.find(player => player.id === state.activePlayerId) || null;
    }
  },
  mutations: {
    SET_VIEW: (state, view) => {
      state.currentView = view;
    },
    SET_DISPLAY_SHEET: (state, sheet) => {
      state.displaySheet = sheet;
    },
    SET_GAMES: (state, games) => {
      state.games = games;
    },
    UPSERT_GAME: (state, game) => {
      const index = state.games.findIndex(g => g.id === game.id);
      if (index >= 0) {
        Vue.set(state.games, index, { ...state.games[index], ...game });
      } else {
        state.games = [game, ...state.games];
      }
    },
    SET_ACTIVE_GAME: (state, game) => {
      state.activeGame = game;
    },
    SET_ACTIVE_PLAYER: (state, playerId) => {
      state.activePlayerId = playerId;
    },
    UPDATE_ACTIVE_PLAYER: (state, player) => {
      if (!state.activeGame) return;
      const players = state.activeGame.players ?? [];
      const index = players.findIndex(p => p.id === player.id);
      if (index >= 0) {
        Vue.set(players, index, { ...players[index], ...player });
      }
      if (player.lastModifiedAt) {
        state.activeGame.updatedAt = player.lastModifiedAt;
      }
    },
    SET_AUDIT_ENTRIES: (state, entries) => {
      state.auditEntries = entries;
    },
    APPEND_AUDIT_ENTRIES: (state, entries) => {
      state.auditEntries = [...state.auditEntries, ...entries];
    },
    SET_AUDIT_PAGINATION: (state, pagination) => {
      state.auditPagination = { ...state.auditPagination, ...pagination };
    },
    SET_LEADERBOARD: (state, entries) => {
      state.leaderboard = entries;
    },
    SET_LOADING: (state, { key, value }) => {
      state.loading = { ...state.loading, [key]: value };
    },
    SET_ERROR: (state, error) => {
      state.error = error;
    }
  },
  actions: {
    async fetchGames({ commit }) {
      commit("SET_LOADING", { key: "games", value: true });
      commit("SET_ERROR", null);
      try {
        const games = await listGames();
        commit("SET_GAMES", games);
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to load games");
      } finally {
        commit("SET_LOADING", { key: "games", value: false });
      }
    },
    async createGame({ commit, dispatch }, payload) {
      commit("SET_LOADING", { key: "createGame", value: true });
      commit("SET_ERROR", null);
      try {
        const game = await createGame(payload);
        commit("UPSERT_GAME", game);
        commit("SET_ACTIVE_GAME", game);
        commit("SET_VIEW", "game-screen");
        if (game.players?.length) {
          commit("SET_ACTIVE_PLAYER", game.players[0].id);
          applySheetStateToModules(commit, game.players[0].sheetState || {});
        } else {
          commit("SET_ACTIVE_PLAYER", null);
          applySheetStateToModules(commit, {});
        }
        await dispatch("fetchGames");
        return game;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to create game");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "createGame", value: false });
      }
    },
    async loadGame({ commit }, gameId) {
      commit("SET_LOADING", { key: "game", value: true });
      commit("SET_ERROR", null);
      try {
        const game = await getGame(gameId);
        commit("SET_ACTIVE_GAME", game);
        commit("UPSERT_GAME", game);
        commit("SET_VIEW", "game-screen");
        const firstPlayer = game.players?.[0];
        if (firstPlayer) {
          commit("SET_ACTIVE_PLAYER", firstPlayer.id);
          applySheetStateToModules(commit, firstPlayer.sheetState || {});
        } else {
          commit("SET_ACTIVE_PLAYER", null);
          applySheetStateToModules(commit, {});
        }
        commit("SET_AUDIT_ENTRIES", []);
        commit("SET_AUDIT_PAGINATION", { offset: 0, endReached: false });
        return game;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to load game");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "game", value: false });
      }
    },
    selectPlayer({ commit, getters, dispatch }, playerId) {
      commit("SET_ACTIVE_PLAYER", playerId);
      dispatch("hydrateActivePlayer", playerId);
      commit("SET_VIEW", "player-sheet");
    },
    hydrateActivePlayer({ commit, getters }, playerId = null) {
      const activeGame = getters.activeGame;
      if (!activeGame) return;
      const targetId = playerId || getters.activePlayer?.id;
      if (!targetId) return;
      const player = activeGame.players?.find(p => p.id === targetId);
      if (player) {
        applySheetStateToModules(commit, player.sheetState || {});
      }
    },
    async savePlayerSheet({ state, commit, rootState }, { audit }) {
      if (!state.activeGame || !state.activePlayerId) {
        throw new Error("No active game or player selected");
      }
      commit("SET_LOADING", { key: "playerSave", value: true });
      commit("SET_ERROR", null);
      try {
        const sheetState = buildSheetState(rootState);
        const player = await updatePlayerSheet(state.activeGame.id, state.activePlayerId, {
          sheetState,
          audit
        });
        commit("UPDATE_ACTIVE_PLAYER", { ...player, sheetState });
        commit("UPSERT_GAME", { ...state.activeGame, updatedAt: player.lastModifiedAt });
        return player;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to save player sheet");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "playerSave", value: false });
      }
    },
    async fetchAudit({ state, commit }, { reset = false } = {}) {
      if (!state.activeGame) return [];
      const offset = reset ? 0 : state.auditPagination.offset;
      const limit = state.auditPagination.limit;
      commit("SET_LOADING", { key: "audit", value: true });
      commit("SET_ERROR", null);
      try {
        const entries = await getAuditLog(state.activeGame.id, { offset, limit });
        if (reset) {
          commit("SET_AUDIT_ENTRIES", entries);
        } else {
          commit("APPEND_AUDIT_ENTRIES", entries);
        }
        const nextOffset = offset + entries.length;
        commit("SET_AUDIT_PAGINATION", {
          offset: nextOffset,
          endReached: entries.length < limit
        });
        return entries;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to fetch audit log");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "audit", value: false });
      }
    },
    async completeGame({ state, commit }, payload) {
      if (!state.activeGame) {
        throw new Error("No active game selected");
      }
      commit("SET_LOADING", { key: "game", value: true });
      commit("SET_ERROR", null);
      try {
        const result = await endGame(state.activeGame.id, payload);
        const updatedGame = { ...state.activeGame, ...result, status: "completed" };
        commit("SET_ACTIVE_GAME", updatedGame);
        commit("UPSERT_GAME", updatedGame);
        return result;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to complete game");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "game", value: false });
      }
    },
    async fetchLeaderboard({ commit }, params = {}) {
      commit("SET_LOADING", { key: "leaderboard", value: true });
      commit("SET_ERROR", null);
      try {
        const entries = await getLeaderboard(params);
        commit("SET_LEADERBOARD", entries);
        commit("SET_VIEW", "leaderboard");
        return entries;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to load leaderboard");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "leaderboard", value: false });
      }
    },
    resetSheetToDefaults({ commit }) {
      applySheetStateToModules(commit, {});
      commit("SET_DISPLAY_SHEET", "Rat Race");
    },
    navigate({ commit }, view) {
      commit("SET_VIEW", view);
    }
  },
  modules: {
    income,
    expenses,
    liabilities,
    meta,
    assets,
    investments,
    fasttrack
  }
});
