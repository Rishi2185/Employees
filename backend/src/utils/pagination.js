'use strict';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

/** Coerce ?page & ?limit query params into safe { page, limit, skip }. */
function parsePaging(query = {}) {
  let page = parseInt(query.page, 10);
  let limit = parseInt(query.limit, 10);
  if (!Number.isInteger(page) || page < 1) page = 1;
  if (!Number.isInteger(limit) || limit < 1) limit = DEFAULT_LIMIT;
  if (limit > MAX_LIMIT) limit = MAX_LIMIT;
  return { page, limit, skip: (page - 1) * limit };
}

/** Standard list envelope returned by every paginated endpoint. */
function envelope(data, { page, limit }, total) {
  return { data, page, limit, total };
}

module.exports = { parsePaging, envelope, DEFAULT_LIMIT, MAX_LIMIT };
