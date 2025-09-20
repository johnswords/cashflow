const jsonHeaders = {
  Accept: "application/json",
  "Content-Type": "application/json"
};

async function request(path, options = {}) {
  const response = await fetch(`/api${path}`, {
    ...options,
    headers: options.body ? { ...jsonHeaders, ...(options.headers || {}) } : options.headers,
    credentials: "same-origin"
  });

  if (!response.ok) {
    let payload;
    try {
      payload = await response.json();
    } catch (err) {
      payload = { message: response.statusText };
    }
    const error = new Error(payload.message || "Request failed");
    error.status = response.status;
    error.payload = payload;
    throw error;
  }

  if (response.status === 204) return null;
  return response.json();
}

export const listGames = () => request("/games");

export const createGame = payload =>
  request("/games", {
    method: "POST",
    body: JSON.stringify(payload)
  });

export const getGame = gameId => request(`/games/${gameId}`);

export const updatePlayerSheet = (gameId, playerId, payload) =>
  request(`/games/${gameId}/players/${playerId}`, {
    method: "PATCH",
    body: JSON.stringify(payload)
  });

export const appendAuditEntry = (gameId, payload) =>
  request(`/games/${gameId}/audit`, {
    method: "POST",
    body: JSON.stringify(payload)
  });

export const getAuditLog = (gameId, params = {}) => {
  const query = new URLSearchParams(params).toString();
  const suffix = query ? `?${query}` : "";
  return request(`/games/${gameId}/audit${suffix}`);
};

export const endGame = (gameId, payload) =>
  request(`/games/${gameId}/end`, {
    method: "POST",
    body: JSON.stringify(payload)
  });

export const getLeaderboard = (params = {}) => {
  const query = new URLSearchParams(params).toString();
  const suffix = query ? `?${query}` : "";
  return request(`/leaderboard${suffix}`);
};
