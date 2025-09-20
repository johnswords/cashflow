export const initialAssetsState = () => ({
  savings: 0
});

export default {
  namespaced: true,
  state: initialAssetsState(),
  mutations: {
    changeSavings: (state, payload) => (state.savings = payload),
    resetState: state => Object.assign(state, initialAssetsState()),
    replaceState: (state, payload = {}) => Object.assign(state, initialAssetsState(), payload)
  }
};
