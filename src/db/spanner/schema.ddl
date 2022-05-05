-- fxa_uid: a 16 byte identifier, randomly generated by the fxa server
--    usually a UUID, so presuming a formatted form.
-- fxa_kid: <`mono_num`>-<`client_state`>
--
-- - mono_num: a monotonically increasing timestamp or generation number
--             in hex and padded to 13 digits, provided by the fxa server
-- - client_state: the first 16 bytes of a SHA256 hash of the user's sync
--             encryption key.
--
-- NOTE: DO NOT INCLUDE COMMENTS IF PASTING INTO CONSOLE
--       ALSO, CONSOLE WANTS ONE SPACE BETWEEN DDL COMMANDS

CREATE TABLE user_collections (
  fxa_uid STRING(MAX)  NOT NULL,
  fxa_kid STRING(MAX)  NOT NULL,
  collection_id INT64  NOT NULL,
  modified TIMESTAMP   NOT NULL,

  count INT64,
  total_bytes INT64,
) PRIMARY KEY(fxa_uid, fxa_kid, collection_id);

CREATE TABLE bsos (
  fxa_uid STRING(MAX)  NOT NULL,
  fxa_kid STRING(MAX)  NOT NULL,
  collection_id INT64  NOT NULL,
  bso_id STRING(MAX)   NOT NULL,

  sortindex INT64,

  payload STRING(MAX)  NOT NULL,

  modified TIMESTAMP   NOT NULL,
  expiry TIMESTAMP     NOT NULL,
)    PRIMARY KEY(fxa_uid, fxa_kid, collection_id, bso_id),
  INTERLEAVE IN PARENT user_collections ON DELETE CASCADE;

    CREATE INDEX BsoModified
        ON bsos(fxa_uid, fxa_kid, collection_id, modified DESC),
INTERLEAVE IN user_collections;

    CREATE INDEX BsoExpiry
        ON bsos(fxa_uid, fxa_kid, collection_id, expiry),
INTERLEAVE IN user_collections;

CREATE TABLE collections (
  collection_id INT64  NOT NULL,
  name STRING(32)      NOT NULL,
) PRIMARY KEY(collection_id);

    CREATE UNIQUE INDEX CollectionName
        ON collections(name);

CREATE TABLE batches (
  fxa_uid STRING(MAX)  NOT NULL,
  fxa_kid STRING(MAX)  NOT NULL,
  collection_id INT64  NOT NULL,
  batch_id STRING(MAX) NOT NULL,
  expiry TIMESTAMP     NOT NULL,
)    PRIMARY KEY(fxa_uid, fxa_kid, collection_id, batch_id),
  INTERLEAVE IN PARENT user_collections ON DELETE CASCADE;

    CREATE INDEX BatchExpireId
        ON batches(fxa_uid, fxa_kid, collection_id, expiry),
INTERLEAVE IN user_collections;

CREATE TABLE batch_bsos (
  fxa_uid STRING(MAX)      NOT NULL,
  fxa_kid STRING(MAX)      NOT NULL,
  collection_id INT64      NOT NULL,
  batch_id STRING(MAX)     NOT NULL,
  batch_bso_id STRING(MAX) NOT NULL,

  sortindex INT64,
  payload STRING(MAX),
  ttl INT64,
)    PRIMARY KEY(fxa_uid, fxa_kid, collection_id, batch_id, batch_bso_id),
  INTERLEAVE IN PARENT batches ON DELETE CASCADE;

-- batch_bsos' bso fields are nullable as the batch upload may or may
-- not set each individual field of each item. Also note that there's
-- no "modified" column because the modification timestamp gets set on
-- batch commit.

-- *NOTE*:
-- Newly created Spanner instances should pre-populate the `collections` table by
-- running the content of `insert_standard_collections.sql `
