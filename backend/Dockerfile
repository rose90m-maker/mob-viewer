# Synology에서 빌드 가능한 멀티스테이지 Dockerfile
# (Synology가 ARM이면 platform 명시 필요할 수도 있음)

FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY tsconfig.json nest-cli.json ./
COPY prisma ./prisma
COPY src ./src

RUN npx prisma generate
RUN npm run build

# --- Production stage ---
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

EXPOSE 3000

# Prisma 마이그레이션 자동 적용 후 서버 시작
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
