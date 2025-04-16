# 싱크홀 자동 감지 및 시각화 웹 어플리케이션

실시간 싱크홀 발생 정보를 자동으로 수집하고 시각화하는 웹 애플리케이션입니다.
제작기 : https://tabmania.tistory.com/entry/Amazon-Q-Developer-IDE%EB%A1%9C-sink-hole-%ED%91%9C%EC%8B%9C-%EC%9B%B9-%EC%96%B4%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98-%EC%83%9D%EC%84%B1

## 주요 기능

- 연합뉴스 RSS를 통한 싱크홀 관련 뉴스 자동 수집
- Google Maps 기반 위치 시각화
- Slack을 통한 실시간 알림
- 관리자용 좌표 정보 입력 기능

## 시스템 구성

- Frontend: Node.js + Vite
- Backend: AWS Lambda + API Gateway
- Database: DynamoDB
- 자동화: EventBridge
- 알림: Slack Webhook

## 프로젝트 구조

```
.
├── infrastructure/         # AWS CloudFormation 템플릿
├── backend/               # Lambda 함수들
│   ├── collectors/       # RSS 수집기
│   └── api/             # API 엔드포인트
├── frontend/             # Vite 기반 웹 앱
└── docs/                 # 문서
```

## 설치 및 배포

### 사전 준비사항

1. [Node.js](https://nodejs.org/) 설치
2. [AWS CLI](https://aws.amazon.com/cli/) 설치 및 설정
3. 필요한 환경 변수 설정

### Windows에서 배포하기

PowerShell을 관리자 권한으로 실행한 후:

방법 1 - 대화형 설정 (권장):
```powershell
# 환경 변수 설정 스크립트 실행
.\setup-env.ps1

# 배포 스크립트 실행
.\deploy.ps1
```

방법 2 - 수동 설정:
```powershell
# 환경 변수 설정
$env:SLACK_WEBHOOK_URL="your-slack-webhook-url"
$env:GOOGLE_MAPS_API_KEY="your-google-maps-api-key"
$env:RSS_FEED_URL="your-rss-feed-url"

# 배포 스크립트 실행
.\deploy.ps1
```

### Linux/Mac에서 배포하기

방법 1 - 대화형 설정 (권장):
```bash
# 스크립트 실행 권한 부여
chmod +x setup-env.sh deploy.sh

# 환경 변수 설정 스크립트 실행
./setup-env.sh

# 배포 스크립트 실행
./deploy.sh
```

방법 2 - 수동 설정:
```bash
# 환경 변수 설정
export SLACK_WEBHOOK_URL="your-slack-webhook-url"
export GOOGLE_MAPS_API_KEY="your-google-maps-api-key"
export RSS_FEED_URL="your-rss-feed-url"

# 스크립트 실행 권한 부여
chmod +x deploy.sh

# 배포 스크립트 실행
./deploy.sh
```

### 수동 배포 방법

1. AWS CloudFormation 스택 배포
```bash
cd infrastructure
aws cloudformation deploy --template-file template.yaml --stack-name sinkhole-detector
```

2. Frontend 배포
```bash
cd frontend
npm install
npm run build
```

## 환경 변수

- `SLACK_WEBHOOK_URL`: Slack 알림용 Webhook URL
- `GOOGLE_MAPS_API_KEY`: Google Maps JavaScript API 키
- `RSS_FEED_URL`: 연합뉴스 RSS 피드 URL

## 라이선스

MIT License



