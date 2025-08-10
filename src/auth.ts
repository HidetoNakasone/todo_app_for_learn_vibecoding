import NextAuth from "next-auth"
import { PrismaAdapter } from "@auth/prisma-adapter"
import { PrismaClient } from "@/generated/prisma"

// Prisma クライアントのインスタンス作成
const prisma = new PrismaClient()

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    // 後で OAuth プロバイダーを追加予定
    // 今は基本設定のみ
  ],
  pages: {
    // カスタムページは後で作成予定
    // signIn: '/auth/signin',
    // signOut: '/auth/signout',
  },
  callbacks: {
    session: ({ session, token }) => ({
      ...session,
      user: {
        ...session.user,
        id: token.sub,
      },
    }),
  },
  debug: process.env.NODE_ENV === 'development',
})