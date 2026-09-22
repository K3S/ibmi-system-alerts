**free
// Teaching exercise: enqueue ONE synthetic alert. Does not monitor or post.
// Compile and test on IBM i 7.5 before adapting. See guide/queue.md.
ctl-opt dftactgrp(*no) actgrp(*new) option(*srcstmt);

dcl-s payload varchar(8192) ccsid(1208);
dcl-s eventId char(26);
dcl-s detail varchar(120);

exec sql set option commit = *none, closqlcsr = *endmod;

exec sql values hex(generate_unique()) into :eventId;
if SQLCOD < 0;
  dsply 'Could not create event ID. Inspect job log.';
  *inlr = *on;
  return;
endif;

exec sql
  values json_object(
    'schema_version' value 1,
    'event_id' value :eventId,
    'incident_key' value 'DEMO:TEST',
    'system' value 'TEST-IBM-I',
    'check' value 'TEST',
    'transition' value 'OPEN',
    'priority' value 'INFO',
    'observed_at' value varchar_format(current timestamp,
                                     'YYYY-MM-DD HH24:MI:SS'),
    'time_basis' value 'IBM i job local time',
    'summary' value 'Synthetic alert from the queue exercise'
  ) into :payload;

if SQLCOD < 0;
  dsply 'Could not build JSON. Inspect job log.';
  *inlr = *on;
  return;
endif;

// Payload is UTF-8. This small generated event fits MAXLEN(8192).
// Real producers must check the encoded byte length of larger events.
exec sql
  call QSYS2.SEND_DATA_QUEUE_UTF8(
    MESSAGE_DATA => :payload,
    DATA_QUEUE => 'ALERTQ',
    DATA_QUEUE_LIBRARY => 'ALERTDEMO'
  );

if SQLCOD < 0;
  dsply 'Enqueue failed. Inspect job log; no success recorded.';
else;
  detail = 'Queued test event ' + %trim(eventId);
  dsply %subst(detail: 1: 50);
endif;

*inlr = *on;
return;
