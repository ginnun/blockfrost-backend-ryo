SELECT encode(b.hash, 'hex') AS "hash"
FROM block b
  JOIN slot_leader sl ON (sl.id = b.slot_leader_id)
  JOIN pool_hash ph ON (ph.id = sl.pool_hash_id)
WHERE b.epoch_no = $4
  AND ph.view = $5
ORDER BY CASE
    WHEN LOWER($1) = 'desc' THEN b.id
  END DESC,
  CASE
    WHEN LOWER($1) <> 'desc'
    OR $1 IS NULL THEN b.id
  END ASC
LIMIT CASE
    WHEN $2 >= 1
    AND $2 <= 100 THEN $2
    ELSE 100
  END OFFSET CASE
    WHEN $3 > 1
    AND $3 < 2147483647 THEN ($3 - 1) * (
      CASE
        WHEN $2 >= 1
        AND $2 <= 100 THEN $2
        ELSE 100
      END
    )
    ELSE 0
  END