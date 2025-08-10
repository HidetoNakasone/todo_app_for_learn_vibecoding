import { signIn, signOut, auth } from "@/auth"

export default async function AuthButton() {
  const session = await auth()

  if (session?.user) {
    return (
      <form
        action={async () => {
          "use server"
          await signOut()
        }}
        className="inline"
      >
        <div className="flex items-center gap-4">
          <p className="text-sm text-gray-600">
            Signed in as <span className="font-medium">{session.user.email}</span>
          </p>
          <button
            type="submit"
            className="px-4 py-2 bg-red-500 text-white text-sm rounded hover:bg-red-600 transition-colors"
          >
            Sign out
          </button>
        </div>
      </form>
    )
  }

  return (
    <form
      action={async () => {
        "use server"
        await signIn()
      }}
      className="inline"
    >
      <button
        type="submit"
        className="px-4 py-2 bg-blue-500 text-white text-sm rounded hover:bg-blue-600 transition-colors"
      >
        Sign in
      </button>
    </form>
  )
}