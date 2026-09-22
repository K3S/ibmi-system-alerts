-- Reads one event without removing it. No webhook is called.
SELECT MESSAGE_DATA_UTF8
FROM TABLE
(
    QSYS2.RECEIVE_DATA_QUEUE(
        DATA_QUEUE => 'ALERTQ',
        DATA_QUEUE_LIBRARY => 'ALERTDEMO',
        REMOVE => 'NO',
        WAIT_TIME => 0
    )
) AS Q;
