export const initialMetaState = () => ({
  profession: "",
  player: "",
  auditor: ""
});

export default {
  namespaced: true,
  state: initialMetaState(),
  mutations: {
    changeProfession: (state, payload) => (state.profession = payload),
    changePlayer: (state, payload) => (state.player = payload),
    changeAuditor: (state, payload) => (state.auditor = payload),
    resetState: state => Object.assign(state, initialMetaState()),
    replaceState: (state, payload = {}) => Object.assign(state, initialMetaState(), payload)
  }
};
