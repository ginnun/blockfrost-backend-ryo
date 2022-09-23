WITH queried_stakes AS (
  SELECT es.epoch_no AS "epoch_no",
    SUM(es.amount) AS "amount"
  FROM epoch_stake es
  WHERE es.epoch_no = $1
  GROUP BY es.epoch_no
)
SELECT e.no AS "epoch",
  (
    extract(
      epoch
      FROM (
          SELECT e.no * ($2 || 'SECONDS')::INTERVAL + (
              SELECT start_time
              FROM meta
              ORDER BY id
              LIMIT 1
            )
        )
    )
  ) AS "start_time",
  (
    extract(
      epoch
      FROM (
          SELECT (e.no + 1) * ($2 || 'SECONDS')::INTERVAL + (
              SELECT start_time
              FROM meta
              ORDER BY id
              LIMIT 1
            )
        )
    )
  ) AS "end_time",
  extract(
    epoch
    FROM e.start_time
  ) AS "first_block_time",
  extract(
    epoch
    FROM e.end_time
  ) AS "last_block_time",
  e.blk_count AS "block_count",
  e.tx_count AS "tx_count",
  e.out_sum::TEXT AS "output", -- cast to TEXT to avoid number overflow
  e.fees::TEXT AS "fees", -- cast to TEXT to avoid number overflow
  q.amount::TEXT AS "active_stake" -- cast to TEXT to avoid number overflow
FROM epoch e
  LEFT JOIN queried_stakes q ON (e.no = q.epoch_no)
WHERE e.no = $1