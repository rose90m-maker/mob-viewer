# mob-viewer mobile (Flutter)

## 처음 실행 (노트북에서)

```bash
# Flutter 설치 확인
flutter doctor

# Android 플랫폼 폴더 생성 (최초 1회)
flutter create --platforms=android --project-name mob_viewer .

# 의존성 설치
flutter pub get

# Android 에뮬레이터/실기기에서 실행
# (백엔드 URL을 NAS Tailscale IP로 지정)
flutter run --dart-define=API_URL=http://100.x.x.x:3000
```

## API URL 설정

기본값은 Android 에뮬레이터에서 호스트 머신을 가리키는 `http://10.0.2.2:3000`.
실기기에서는 빌드 시 주입:

```bash
flutter build apk --dart-define=API_URL=http://<NAS_TAILSCALE_IP>:3000
```

## 테스트

```bash
flutter test
```

## 폴더 구조

이 디렉토리는 Flutter 프로젝트의 **소스코드만** 커밋되어 있습니다.
Android/iOS 네이티브 폴더(`android/`, `ios/`)와 `.dart_tool/` 등 빌드 산출물은
`.gitignore`로 제외되어 있으며, `flutter create --platforms=android .` 명령으로 생성합니다.
