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

const normalizeSheetState = (sheetState = {}) => {
  const normalized = {
    income: clone(sheetState.income || initialIncomeState()),
    expenses: clone(sheetState.expenses || initialExpensesState()),
    liabilities: clone(sheetState.liabilities || initialLiabilitiesState()),
    assets: clone(sheetState.assets || initialAssetsState()),
    investments: sanitizeInvestmentsForSave(sheetState.investments || initialInvestmentsState()),
    meta: clone(sheetState.meta || initialMetaState()),
    fasttrack: clone(sheetState.fasttrack || initialFastTrackState())
  };

  return normalized;
};

const buildSheetState = rootState =>
  normalizeSheetState({
    income: rootState.income,
    expenses: rootState.expenses,
    liabilities: rootState.liabilities,
    assets: rootState.assets,
    investments: rootState.investments,
    meta: rootState.meta,
    fasttrack: rootState.fasttrack
  });

const applySheetStateToModules = (commit, sheetState = {}, options = {}) => {
  const { setBaseline = true } = options;
  const normalized = normalizeSheetState(sheetState);
  commit("income/replaceState", normalized.income, { root: true });
  commit("expenses/replaceState", normalized.expenses, { root: true });
  commit("liabilities/replaceState", normalized.liabilities, { root: true });
  commit("assets/replaceState", normalized.assets, { root: true });
  commit("investments/replaceState", normalized.investments, { root: true });
  commit("meta/replaceState", normalized.meta, { root: true });
  commit("fasttrack/replaceState", normalized.fasttrack, { root: true });
  if (setBaseline) {
    commit("SET_ACTIVE_SHEET_BASELINE", clone(normalized));
  }
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
  displaySheet: "Rat Race",
  activeSheetBaseline: normalizeSheetState(),
  activeAuditPlayerId: null,
  pendingAuditContext: null,
  endGameForm: { winnerPlayerId: null, winnerComment: "" },
  ui: {
    auditModal: false,
    endGameModal: false
  },
  preferences: {
    audioEnabled: true
  }
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
    },
    currentSheetState: (_state, _getters, rootState) => buildSheetState(rootState),
    auditEntries: state => state.auditEntries,
    auditEntriesByPlayer: state => playerId =>
      state.auditEntries.filter(entry => entry.playerId === playerId).slice(0, 10),
    pendingAuditContext: state => state.pendingAuditContext,
    isAuditModalOpen: state => state.ui.auditModal,
    isEndGameModalOpen: state => state.ui.endGameModal,
    endGameForm: state => state.endGameForm,
    isAudioEnabled: state => state.preferences.audioEnabled
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
      state.endGameForm = {
        winnerPlayerId: game?.winnerPlayerId || game?.players?.[0]?.id || null,
        winnerComment: game?.winnerComment || ""
      };
      state.activeAuditPlayerId = null;
      state.pendingAuditContext = null;
      state.ui.auditModal = false;
      state.ui.endGameModal = false;
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
    },
    SET_ACTIVE_SHEET_BASELINE: (state, baseline) => {
      state.activeSheetBaseline = baseline;
    },
    SET_ACTIVE_AUDIT_PLAYER: (state, playerId) => {
      state.activeAuditPlayerId = playerId;
    },
    SHOW_AUDIT_MODAL: state => {
      state.ui.auditModal = true;
    },
    HIDE_AUDIT_MODAL: state => {
      state.ui.auditModal = false;
    },
    SET_PENDING_AUDIT_CONTEXT: (state, context) => {
      state.pendingAuditContext = context;
    },
    SET_END_GAME_FORM: (state, payload) => {
      state.endGameForm = { ...state.endGameForm, ...payload };
    },
    SHOW_END_GAME_MODAL: state => {
      state.ui.endGameModal = true;
    },
    HIDE_END_GAME_MODAL: state => {
      state.ui.endGameModal = false;
    },
    SET_AUDIO_ENABLED: (state, enabled) => {
      state.preferences.audioEnabled = enabled;
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
        commit("SET_PENDING_AUDIT_CONTEXT", null);
        await dispatch("fetchGames");
        await dispatch("fetchAudit", { reset: true });
        return game;
      } catch (error) {
        commit("SET_ERROR", error.message || "Failed to create game");
        throw error;
      } finally {
        commit("SET_LOADING", { key: "createGame", value: false });
      }
    },
    async loadGame({ commit, dispatch }, gameId) {
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
        await dispatch("fetchAudit", { reset: true });
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
      commit("SET_PENDING_AUDIT_CONTEXT", null);
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
    async savePlayerSheet({ state, commit, rootState, dispatch }, { audit }) {
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
        commit("SET_ACTIVE_SHEET_BASELINE", clone(sheetState));
        commit("SET_PENDING_AUDIT_CONTEXT", null);
        await dispatch("fetchAudit", { reset: true });
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
      commit("SET_PENDING_AUDIT_CONTEXT", null);
    },
    navigate({ commit }, view) {
      commit("SET_VIEW", view);
    },
    openAuditLog({ commit, dispatch, state }, playerId = null) {
      const targetPlayerId = playerId || state.activePlayerId || null;
      commit("SET_ACTIVE_AUDIT_PLAYER", targetPlayerId);
      commit("SHOW_AUDIT_MODAL");
      dispatch("fetchAudit", { reset: true });
    },
    closeAuditLog({ commit }) {
      commit("HIDE_AUDIT_MODAL");
      commit("SET_ACTIVE_AUDIT_PLAYER", null);
    },
    startCorrection({ commit }, entry) {
      if (!entry) return;
      commit("SET_PENDING_AUDIT_CONTEXT", { type: "correction", originEntryId: entry.id });
      commit("SET_ACTIVE_AUDIT_PLAYER", entry.playerId);
      commit("SET_ACTIVE_PLAYER", entry.playerId);
      applySheetStateToModules(commit, entry.afterSnapshot || {});
      commit("UPDATE_ACTIVE_PLAYER", { id: entry.playerId, sheetState: entry.afterSnapshot || {} });
      commit("HIDE_AUDIT_MODAL");
      commit("SET_VIEW", "player-sheet");
    },
    clearAuditContext({ commit }) {
      commit("SET_PENDING_AUDIT_CONTEXT", null);
    },
    openEndGameModal({ commit, state }) {
      if (state.activeGame?.players?.length && !state.endGameForm.winnerPlayerId) {
        commit("SET_END_GAME_FORM", { winnerPlayerId: state.activeGame.players[0].id });
      }
      commit("SHOW_END_GAME_MODAL");
    },
    closeEndGameModal({ commit }) {
      commit("HIDE_END_GAME_MODAL");
    },
    updateEndGameForm({ commit }, payload) {
      commit("SET_END_GAME_FORM", payload);
    },
    async submitEndGame({ state, commit, dispatch }) {
      if (!state.activeGame) throw new Error("No active game selected");
      const payload = {
        winnerPlayerId: state.endGameForm.winnerPlayerId,
        winnerComment: state.endGameForm.winnerComment || undefined
      };
      await dispatch("completeGame", payload);
      commit("HIDE_END_GAME_MODAL");
      await dispatch("fetchLeaderboard");
      await dispatch("fetchGames");
    },
    toggleAudio({ state, commit }, enabled) {
      const next = typeof enabled === "boolean" ? enabled : !state.preferences.audioEnabled;
      commit("SET_AUDIO_ENABLED", next);
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
