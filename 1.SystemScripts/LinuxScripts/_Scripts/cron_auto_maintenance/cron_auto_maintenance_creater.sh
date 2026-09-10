#!/bin/bash
#
# setup-maintenance-full.sh
#
#   apt の自動メンテナンス環境を一括セットアップするスクリプト。
#
#   実行すると以下を行う:
#     1. メンテナンス本体スクリプト  /usr/local/sbin/maintenance_full.sh  を生成
#     2. ログファイル               /var/log/maintenance_full.log        を作成
#     3. logrotate 設定             /etc/logrotate.d/maintenance_full    を作成
#     4. root の crontab に毎日 01:00 実行のジョブを登録（冪等）
#
#   使い方:  sudo bash setup-maintenance-full.sh
#   再実行しても安全（上書き・重複登録なし）。
#

set -euo pipefail

# ------------------------------------------------------------------
# 設定（必要に応じて変更）
# ------------------------------------------------------------------
SCRIPT_PATH="/usr/local/sbin/maintenance_full.sh"
LOG_FILE="/var/log/maintenance_full.log"
LOGROTATE_CONF="/etc/logrotate.d/maintenance_full"
CRON_MIN="0"          # 分
CRON_HOUR="1"         # 時（デフォルト: 午前1時）
UPGRADE_CMD="full-upgrade"   # 保守的にしたい場合は "upgrade" に変更
LOCK_TIMEOUT="600"    # apt ロック待機の上限（秒）

# ------------------------------------------------------------------
# 表示用ヘルパー
# ------------------------------------------------------------------
info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
die()   { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------
# 0. 事前チェック
# ------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "root で実行してください:  sudo bash $0"

command -v apt-get  >/dev/null 2>&1 || die "apt-get が見つかりません（Debian/Ubuntu 系専用です）"
command -v crontab  >/dev/null 2>&1 || die "crontab が見つかりません。'apt-get install -y cron' を実行してください。"

info "セットアップを開始します"

# ------------------------------------------------------------------
# 1. メンテナンス本体スクリプトを生成
#    ※ 'EOF' をクォートして変数展開を抑止し、中身をそのまま書き出す
# ------------------------------------------------------------------
info "本体スクリプトを作成: ${SCRIPT_PATH}"

cat > "${SCRIPT_PATH}" <<'MAINTENANCE_EOF'
#!/bin/bash
#
# maintenance_full.sh - apt のフル更新・不要パッケージ削除・キャッシュ削除
#   （setup-maintenance-full.sh により自動生成。手動編集する場合は上書きに注意）
#
set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a          # needrestart のプロンプトを抑止（サービス自動再起動）
# export NEEDRESTART_SUSPEND=1     # サービス再起動を一切させたくない場合はこちらを有効化

echo "========== $(date '+%F %T %Z') START =========="

echo "--- apt-get update ---"
apt-get update

echo "--- apt-get __UPGRADE_CMD__ ---"
apt-get -y \
    -o Dpkg::Options::="--force-confold" \
    -o DPkg::Lock::Timeout=__LOCK_TIMEOUT__ \
    __UPGRADE_CMD__

echo "--- apt-get autoremove ---"
apt-get -y -o DPkg::Lock::Timeout=__LOCK_TIMEOUT__ autoremove

echo "--- apt-get clean ---"
apt-get clean

if [ -f /var/run/reboot-required ]; then
    echo "!! 再起動が必要です (/var/run/reboot-required)"
    if [ -f /var/run/reboot-required.pkgs ]; then
        echo "   対象パッケージ:"
        sed 's/^/     - /' /var/run/reboot-required.pkgs
    fi
fi

echo "========== $(date '+%F %T %Z') END =========="
echo
MAINTENANCE_EOF

# プレースホルダを設定値へ置換
sed -i \
    -e "s|__UPGRADE_CMD__|${UPGRADE_CMD}|g" \
    -e "s|__LOCK_TIMEOUT__|${LOCK_TIMEOUT}|g" \
    "${SCRIPT_PATH}"

chown root:root "${SCRIPT_PATH}"
chmod 700 "${SCRIPT_PATH}"

# 構文チェック
bash -n "${SCRIPT_PATH}" || die "生成したスクリプトに構文エラーがあります"
ok "本体スクリプトを作成しました（構文チェック済み）"

# ------------------------------------------------------------------
# 2. ログファイルを準備
# ------------------------------------------------------------------
info "ログファイルを準備: ${LOG_FILE}"
touch "${LOG_FILE}"
chown root:root "${LOG_FILE}"
chmod 640 "${LOG_FILE}"
ok "ログファイルを準備しました"

# ------------------------------------------------------------------
# 3. logrotate 設定
# ------------------------------------------------------------------
info "logrotate 設定を作成: ${LOGROTATE_CONF}"
cat > "${LOGROTATE_CONF}" <<LOGROTATE_EOF
${LOG_FILE} {
    monthly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
LOGROTATE_EOF
chmod 644 "${LOGROTATE_CONF}"
ok "logrotate 設定を作成しました（月次ローテート・12世代保持）"

# ------------------------------------------------------------------
# 4. root の crontab に登録（既存の同一ジョブは置き換え）
# ------------------------------------------------------------------
CRON_LINE="${CRON_MIN} ${CRON_HOUR} * * * ${SCRIPT_PATH} >> ${LOG_FILE} 2>&1"
info "crontab に登録: ${CRON_LINE}"

TMP_CRON="$(mktemp)"
trap 'rm -f "${TMP_CRON}"' EXIT

# 既存 crontab から本スクリプトに関する行を除去 → 新しい行を追加
crontab -l 2>/dev/null | grep -vF "${SCRIPT_PATH}" > "${TMP_CRON}" || true
{
    echo "# apt full maintenance (managed by setup-maintenance-full.sh)"
    echo "${CRON_LINE}"
} >> "${TMP_CRON}"

# 重複コメント行の掃除（再実行時に増殖しないように）
awk '!(/^# apt full maintenance \(managed by setup-maintenance-full\.sh\)$/ && seen++)' \
    "${TMP_CRON}" > "${TMP_CRON}.clean"
mv "${TMP_CRON}.clean" "${TMP_CRON}"

crontab "${TMP_CRON}"
ok "crontab に登録しました"

# ------------------------------------------------------------------
# 5. 事後確認
# ------------------------------------------------------------------
echo
info "=== 登録内容の確認 ==="
crontab -l | sed 's/^/    /'
echo

# cron サービスの稼働確認
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        ok "cron サービスは稼働中です"
    else
        warn "cron サービスが停止しています。'systemctl enable --now cron' を実行してください"
    fi
fi

# タイムゾーン確認
if command -v timedatectl >/dev/null 2>&1; then
    TZ_NAME="$(timedatectl show -p Timezone --value 2>/dev/null || echo unknown)"
    info "システムのタイムゾーン: ${TZ_NAME}（現在時刻: $(date '+%F %T %Z')）"
    if [ "${TZ_NAME}" != "Asia/Tokyo" ]; then
        warn "cron は上記タイムゾーンで動作します。日本時間で実行したい場合は 'timedatectl set-timezone Asia/Tokyo' を検討してください"
    fi
fi

echo
ok "セットアップ完了"
cat <<SUMMARY_EOF

  本体スクリプト : ${SCRIPT_PATH}
  ログ           : ${LOG_FILE}
  logrotate 設定 : ${LOGROTATE_CONF}
  実行スケジュール: 毎日 ${CRON_HOUR}:$(printf '%02d' "${CRON_MIN}")（システムのタイムゾーン基準）

  次の作業:
    1) 手動テスト     : sudo ${SCRIPT_PATH}
    2) ログ確認       : sudo tail -f ${LOG_FILE}
    3) cron 起動確認  : journalctl -u cron --since today | grep maintenance
    4) 設定削除       : sudo crontab -e で該当行を削除し、
                        sudo rm ${SCRIPT_PATH} ${LOGROTATE_CONF}

SUMMARY_EOF
