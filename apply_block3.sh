#!/bin/bash
# Security Audit Block 3: Final Hardening
# Direkte Anwendung ohne Patch-Datei
set -e

echo "=== Security Audit Block 3 ==="
echo ""

# Helper: Add 'import dart:math;' after a specific import line if not present
add_math_import() {
    local file="$1"
    local after_pattern="$2"
    if ! grep -q "import 'dart:math';" "$file"; then
        sed -i "/${after_pattern}/a import 'dart:math';" "$file"
        echo "  + dart:math import hinzugefügt"
    fi
}

# Helper: Replace timestamp-based subscription ID with Random.secure()
fix_subid() {
    local file="$1"
    local old_pattern="$2"  # e.g. final subId = 'nip05-\${DateTime.now().millisecondsSinceEpoch}';
    local prefix="$3"       # e.g. nip05
    local varname="$4"      # e.g. subId or subscriptionId
    
    # Build the new code block
    local new_code="// Security Audit M4: Kryptographisch sichere Subscription-ID\n      final random = Random.secure();\n      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();\n      final ${varname} = '${prefix}-\$subIdHex';"
    
    # Use python for reliable multiline replacement
    python3 -c "
import sys
with open('$file', 'r') as f:
    content = f.read()
old = \"final ${varname} = '${prefix}-\${DateTime.now().millisecondsSinceEpoch}';\"
new = '''// Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final ${varname} = '${prefix}-\\\$subIdHex';'''
if old in content:
    content = content.replace(old, new)
    with open('$file', 'w') as f:
        f.write(content)
    print('  + SubID gefixt: ${varname}')
else:
    print('  ! Pattern nicht gefunden: ${varname} (evtl. bereits gefixt)')
"
}

echo "[1/8] lib/services/admin_registry.dart"
add_math_import "lib/services/admin_registry.dart" "import 'app_logger.dart';"
fix_subid "lib/services/admin_registry.dart" "" "admin-list" "subscriptionId"

echo "[2/8] lib/services/promotion_claim_service.dart"
add_math_import "lib/services/promotion_claim_service.dart" "import 'app_logger.dart';"
fix_subid "lib/services/promotion_claim_service.dart" "" "organic-claims" "subscriptionId"

echo "[3/8] lib/services/reputation_publisher.dart"
add_math_import "lib/services/reputation_publisher.dart" "import 'app_logger.dart';"
fix_subid "lib/services/reputation_publisher.dart" "" "rep-fetch" "subscriptionId"

echo "[4/8] lib/services/nip05_service.dart"
add_math_import "lib/services/nip05_service.dart" "import 'secure_key_store.dart';"
fix_subid "lib/services/nip05_service.dart" "" "nip05" "subId"

echo "[5/8] lib/services/zap_verification_service.dart"
add_math_import "lib/services/zap_verification_service.dart" "import 'secure_key_store.dart';"
fix_subid "lib/services/zap_verification_service.dart" "" "zaps" "subId"

echo "[6/8] lib/services/social_graph_service.dart"
add_math_import "lib/services/social_graph_service.dart" "import 'admin_registry.dart';"
fix_subid "lib/services/social_graph_service.dart" "" "contacts" "subId"

echo "[7/8] lib/services/humanity_proof_service.dart"
add_math_import "lib/services/humanity_proof_service.dart" "import 'secure_key_store.dart';"
# This one has TWO subscription IDs in one spot + one separate
python3 -c "
with open('lib/services/humanity_proof_service.dart', 'r') as f:
    content = f.read()

# Fix the dual subId1/subId2
old1 = \"final subId1 = 'zap-recv-\${DateTime.now().millisecondsSinceEpoch}';\n      final subId2 = 'zap-sent-\${DateTime.now().millisecondsSinceEpoch}';\"
new1 = '''// Security Audit M4: Kryptographisch sichere Subscription-IDs
      final random = Random.secure();
      final hex1 = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final hex2 = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId1 = 'zap-recv-\\\$hex1';
      final subId2 = 'zap-sent-\\\$hex2';'''

# Fix the single verify subId
old2 = \"final subId = 'verify-\${DateTime.now().millisecondsSinceEpoch}';\"
new2 = '''// Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'verify-\\\$subIdHex';'''

changed = False
if old1 in content:
    content = content.replace(old1, new1)
    changed = True
    print('  + SubID gefixt: subId1/subId2')
else:
    print('  ! subId1/subId2 Pattern nicht gefunden (evtl. bereits gefixt)')

if old2 in content:
    content = content.replace(old2, new2)
    changed = True
    print('  + SubID gefixt: verify-subId')
else:
    print('  ! verify-subId Pattern nicht gefunden (evtl. bereits gefixt)')

if changed:
    with open('lib/services/humanity_proof_service.dart', 'w') as f:
        f.write(content)
"

echo "[8/8] .github/workflows/build_apk.yml"
python3 -c "
with open('.github/workflows/build_apk.yml', 'r') as f:
    content = f.read()

old = '''    # 6. Bauen
    - name: Build APK
      run: flutter build apk --release

    # 7. Hochladen
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: einundzwanzig-app-release
        path: build/app/outputs/flutter-apk/app-release.apk'''

new = '''    # 6. Bauen (Security Audit M3: Obfuscation aktiviert)
    - name: Build APK
      run: flutter build apk --release --obfuscate --split-debug-info=build/debug-info

    # 7. Hochladen
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: einundzwanzig-app-release
        path: build/app/outputs/flutter-apk/app-release.apk

    # 8. Debug-Symbole sichern (fuer Crash-Analyse)
    - name: Upload Debug Symbols
      uses: actions/upload-artifact@v4
      with:
        name: debug-symbols
        path: build/debug-info/'''

if old in content:
    content = content.replace(old, new)
    with open('.github/workflows/build_apk.yml', 'w') as f:
        f.write(content)
    print('  + CI/CD Obfuscation aktiviert')
else:
    print('  ! CI/CD Pattern nicht gefunden (evtl. bereits gefixt)')
"

echo ""
echo "=== Verification ==="
echo -n "Predictable SubIDs remaining: "
COUNT=$(grep -rn 'millisecondsSinceEpoch' lib/services/ | grep -i 'sub\|subscription' | grep -v 'since\|timestamp\|updated\|checked\|lastPublish\|cache' | wc -l)
if [ "$COUNT" -eq 0 ]; then
    echo "NONE ✓"
else
    echo "$COUNT FOUND ✗"
    grep -rn 'millisecondsSinceEpoch' lib/services/ | grep -i 'sub\|subscription' | grep -v 'since\|timestamp\|updated\|checked\|lastPublish\|cache'
fi

echo -n "Random.secure() services: "
grep -rl "Random.secure" lib/services/ | wc -l

echo -n "CI/CD obfuscation: "
grep -c "obfuscate" .github/workflows/build_apk.yml

echo ""
echo "=== DONE ==="
echo "Jetzt: git add -A && git commit -m 'Security Audit Block 3: Final Hardening'"