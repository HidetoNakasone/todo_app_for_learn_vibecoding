import AuthButton from "@/app/_components/AuthButton";
import Image from "next/image";

export default function Home() {
  return (
    <div className="font-sans grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20">
      <main className="flex flex-col gap-[32px] row-start-2 items-center sm:items-start">
        <Image
          className="dark:invert"
          src="/next.svg"
          alt="Next.js logo"
          width={180}
          height={38}
          priority
        />
        <div className="mb-8">
          <AuthButton />
        </div>

        <ol className="font-mono list-inside list-decimal text-sm/6 text-center sm:text-left">
          <li className="mb-2 tracking-[-.01em]">
            NextAuth.js v5
            セットアップ完了！上のボタンで認証をテストしてください。
          </li>
          <li className="tracking-[-.01em]">
            現在はプロバイダーが設定されていないため、基本的なログイン画面が表示されます。
          </li>
        </ol>
      </main>
    </div>
  );
}
