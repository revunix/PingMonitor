#!/bin/sh

# ============================================
# KONFIGURATION / CONFIGURATION
# ============================================

# Sprache / Language: "de" für Deutsch, "en" for English
LANGUAGE="de"

SERVER="1.1.1.1"
LOG_WINDOW=5            # Anzahl der letzten Pings zur Mittelwertbildung / Number of last pings for average calculation
DEVIATION_FACTOR=2      # Wie viel mal höher als der Mittelwert gilt als Ausreißer / How many times higher than average counts as spike
MIN_ABS_SPIKE=15        # Mind. wieviel ms muss ein Spike mindestens sein / Minimum ms for a spike
INTERVAL=60             # Sekunden zwischen Tests / Seconds between tests

# Telegram-Konfiguration / Telegram Configuration
TG_BOT_TOKEN=""
TG_CHAT_ID=""
SEND_SILENT="yes"        # "yes" für leise Telegram-Nachrichten / "yes" for silent Telegram messages

PINGS=""

# ============================================
# SPRACHFUNKTIONEN / LANGUAGE FUNCTIONS
# ============================================

get_text() {
  case "$1" in
    # Allgemeine Begriffe / General terms
    "min") [ "$LANGUAGE" = "de" ] && echo "Min" || echo "Min" ;;
    "max") [ "$LANGUAGE" = "de" ] && echo "Max" || echo "Max" ;;
    "average") [ "$LANGUAGE" = "de" ] && echo "Mittelwert" || echo "Average" ;;
    "current") [ "$LANGUAGE" = "de" ] && echo "Aktuell" || echo "Current" ;;
    "previous_avg") [ "$LANGUAGE" = "de" ] && echo "Vorheriger Durchschnitt" || echo "Previous Average" ;;
    "detail_measurement") [ "$LANGUAGE" = "de" ] && echo "Detailmessung" || echo "Detail Measurement" ;;
    "statistics") [ "$LANGUAGE" = "de" ] && echo "Statistik" || echo "Statistics" ;;
    "ping_stats") [ "$LANGUAGE" = "de" ] && echo "Ping-Statistik" || echo "Ping Statistics" ;;
    "detail_ping") [ "$LANGUAGE" = "de" ] && echo "Ping-Detailmessung" || echo "Ping Detail Measurement" ;;
    
    # Status-Nachrichten / Status messages  
    "monitor_started") [ "$LANGUAGE" = "de" ] && echo "Ping-Monitor gestartet" || echo "Ping Monitor started" ;;
    "silent_mode") [ "$LANGUAGE" = "de" ] && echo "(leise)" || echo "(silent)" ;;
    "with_notification") [ "$LANGUAGE" = "de" ] && echo "(mit Benachrichtigung)" || echo "(with notification)" ;;
    "new_test") [ "$LANGUAGE" = "de" ] && echo "Neuer Test" || echo "New Test" ;;
    "waiting") [ "$LANGUAGE" = "de" ] && echo "Warte" || echo "Waiting" ;;
    "seconds_next") [ "$LANGUAGE" = "de" ] && echo "Sekunden bis zum nächsten Test..." || echo "seconds until next test..." ;;
    "starting_mtr") [ "$LANGUAGE" = "de" ] && echo "Starte MTR-Test zu" || echo "Starting MTR test to" ;;
    
    # Fehlermeldungen / Error messages
    "no_response") [ "$LANGUAGE" = "de" ] && echo "KEINE ANTWORT" || echo "NO RESPONSE" ;;
    "ping_spike") [ "$LANGUAGE" = "de" ] && echo "PING SPIKE" || echo "PING SPIKE" ;;
    
    *) echo "$1" ;;
  esac
}

# ============================================
# HILFSFUNKTIONEN / HELPER FUNCTIONS  
# ============================================

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

add_ping() {
  PINGS="$PINGS $1"
  COUNT=$(echo $PINGS | wc -w)
  if [ "$COUNT" -gt "$LOG_WINDOW" ]; then
    PINGS=$(echo $PINGS | awk '{for(i=2;i<=NF;i++) printf $i" "; print ""}')
  fi
}

mean_ping() {
  [ -z "$PINGS" ] && echo 0 && return
  SUM=0
  COUNT=0
  for p in $PINGS; do
    SUM=$(echo "$SUM + $p" | bc)
    COUNT=$((COUNT + 1))
  done
  [ "$COUNT" -eq 0 ] && echo 0 && return
  echo "scale=2; $SUM / $COUNT" | bc
}

stat_ping() {
  local min=99999
  local max=0
  local sum=0
  local count=0
  
  for p in $1; do
    [ "$(echo "$p < $min" | bc)" -eq 1 ] && min=$p
    [ "$(echo "$p > $max" | bc)" -eq 1 ] && max=$p
    sum=$(echo "$sum + $p" | bc)
    count=$((count + 1))
  done
  
  avg=$(echo "scale=2; $sum / $count" | bc)
  echo "$(get_text "min"): $min ms, $(get_text "max"): $max ms, $(get_text "average"): $avg ms"
}

telegram_notify() {
  local msg="$1"
  local silent="false"
  [ "$SEND_SILENT" = "yes" ] && silent="true"
  
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d chat_id="$TG_CHAT_ID" \
    -d text="$msg" \
    -d parse_mode="Markdown" \
    -d disable_notification="$silent" > /dev/null
}

# ============================================
# HAUPTPROGRAMM / MAIN PROGRAM
# ============================================

# Telegram-Test-Nachricht beim Start / Telegram test message at startup
if [ "$SEND_SILENT" = "yes" ]; then
  STARTMODE="$(get_text "silent_mode")"
else
  STARTMODE="$(get_text "with_notification")"
fi

telegram_notify "✅ $(get_text "monitor_started") $STARTMODE $([ "$LANGUAGE" = "de" ] && echo "auf" || echo "on") $(hostname) $([ "$LANGUAGE" = "de" ] && echo "um" || echo "at") $(timestamp)"

while true; do
  echo "========================================"
  echo "$(get_text "new_test"): $(timestamp)"
  echo "----------------------------------------"
  
  PING_RESULT=$(ping -c 1 -w 2 $SERVER | grep 'time=')
  
  if [ -n "$PING_RESULT" ]; then
    PING_TIME=$(echo "$PING_RESULT" | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')
    PING_INT=${PING_TIME%.*}
    AVG=$(mean_ping)
    add_ping "$PING_TIME"
    
    IS_SPIKE=0
    COUNT=$(echo $PINGS | wc -w)
    
    if [ "$COUNT" -ge 2 ]; then
      COMP=$(echo "$PING_TIME > $AVG * $DEVIATION_FACTOR && $PING_TIME > $MIN_ABS_SPIKE" | bc)
      if [ "$COMP" -eq 1 ]; then
        IS_SPIKE=1
      fi
    fi
    
    if [ "$IS_SPIKE" -eq 1 ]; then
      MSG="$(get_text "ping_spike"): $SERVER ${PING_TIME} ms ($(get_text "previous_avg"): ${AVG} ms)"
      echo "\033[31m$MSG\033[0m"
      echo "[$(timestamp)] $MSG" >&2
      
      # 5x Ping-Messreihe bei Spike / 5x ping series on spike
      SPIKE_PINGS=""
      for i in 1 2 3 4 5; do
        SPING=$(ping -c 1 -w 2 $SERVER | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')
        [ -n "$SPING" ] && SPIKE_PINGS="$SPIKE_PINGS $SPING"
      done
      
      echo "$(get_text "detail_ping") (5x):$SPIKE_PINGS" >&2
      STAT=$(stat_ping "$SPIKE_PINGS")
      echo "$(get_text "ping_stats"): $STAT" >&2
      
      # MTR-Test nur bei Spike / MTR test only on spike
      echo "$(get_text "starting_mtr") $SERVER ..." >&2
      MTR_REPORT=$(mtr -r -c 3 $SERVER 2>/dev/null)
      echo "$MTR_REPORT" >&2
      
      # Telegram-Benachrichtigung / Telegram notification
      TG_MSG="🚨 *$(get_text "ping_spike")* $([ "$LANGUAGE" = "de" ] && echo "zu" || echo "to") $SERVER!
$(get_text "current"): ${PING_TIME} ms
$(get_text "previous_avg"): ${AVG} ms
$(get_text "detail_measurement") (5x):$SPIKE_PINGS
$(get_text "statistics"): $STAT
$(timestamp)"
      
      telegram_notify "$TG_MSG"
    else
      MSG="OK: $SERVER ${PING_TIME} ms"
      echo "$MSG"
    fi
  else
    MSG="$(get_text "no_response"): $SERVER (ping)"
    echo "$MSG"
  fi
  
  echo "----------------------------------------"
  echo "$(get_text "waiting") $INTERVAL $(get_text "seconds_next")"
  echo ""
  sleep $INTERVAL
done
