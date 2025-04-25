FROM node:20-alpine AS base

# 设置全局环境变量
ENV NEXT_TELEMETRY_DISABLED=1 \
    NODE_ENV="production" \
    PORT=3000 \
    HOSTNAME="0.0.0.0"

# 安装依赖
FROM base AS deps
WORKDIR /app

# 安装pnpm
RUN npm install -g pnpm

# 复制package.json和pnpm-lock.yaml
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# 构建应用
FROM base AS builder
WORKDIR /app

# 安装pnpm
RUN npm install -g pnpm

COPY --from=deps /app/node_modules ./node_modules

COPY . .

# 设置构建时环境变量
ENV NEXT_TELEMETRY_DISABLED=1

RUN pnpm build

# 生产环境
FROM base AS runner
WORKDIR /app

# 设置运行时环境变量
ENV NODE_ENV="production" \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME="0.0.0.0"

# 可以在这里添加其他应用所需的环境变量
# ENV DATABASE_URL="" \
#     JWT_SECRET="" \
#     API_KEY=""

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# 设置正确的权限
RUN mkdir .next
RUN chown nextjs:nodejs .next

# 复制构建输出
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

# 启动时打印环境变量，然后启动应用
CMD echo "运行时环境变量:" && env && node server.js