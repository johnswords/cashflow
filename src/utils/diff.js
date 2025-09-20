const isObject = value => value && typeof value === "object" && !Array.isArray(value);

const serialize = value => {
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return value;
  if (value === null || value === undefined) return value;
  return JSON.parse(JSON.stringify(value));
};

export const diffSheets = (previous = {}, current = {}) => {
  const changes = [];

  const visit = (prev, curr, pathSegments) => {
    const keys = new Set([...Object.keys(prev || {}), ...Object.keys(curr || {})]);
    keys.forEach(key => {
      const nextPath = [...pathSegments, key];
      const prevVal = prev ? prev[key] : undefined;
      const currVal = curr ? curr[key] : undefined;

      if (isObject(prevVal) && isObject(currVal)) {
        visit(prevVal, currVal, nextPath);
        return;
      }

      if (Array.isArray(prevVal) || Array.isArray(currVal)) {
        const prevSerialized = JSON.stringify(prevVal ?? []);
        const currSerialized = JSON.stringify(currVal ?? []);
        if (prevSerialized !== currSerialized) {
          changes.push({
            path: nextPath.join("."),
            before: serialize(prevVal),
            after: serialize(currVal)
          });
        }
        return;
      }

      if (prevVal !== currVal) {
        changes.push({
          path: nextPath.join("."),
          before: serialize(prevVal),
          after: serialize(currVal)
        });
      }
    });
  };

  visit(previous, current, []);

  return {
    changes,
    fieldPaths: changes.map(change => change.path),
    beforeSnapshot: serialize(previous),
    afterSnapshot: serialize(current)
  };
};

export default diffSheets;
