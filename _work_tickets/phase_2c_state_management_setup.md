# Phase 2c: Modern State Management Setup (推定工数: 2-3日)

## 概要

Phase 2b (shadcn/ui) 完了後、Phase 3 (個人TODO機能) 開始前に、TanStack Query + Zustand を用いたモダンな状態管理システムを構築する専門チケット。従来のuseStateベースの状態管理から、Server State (TanStack Query) と Client State (Zustand) を明確に分離した効率的なアーキテクチャに移行する。

**技術スタック**: TanStack Query v5 + Zustand v5 + TypeScript + Next.js 15  
**前提条件**: Phase 2b (shadcn/ui セットアップ) 完了  
**実施タイミング**: Phase 2b完了後、Phase 3 (個人TODO機能) 開始前  
**優先度**: MUST (Phase 3以降の全機能で使用するため必須)

## Phase A: アーキテクチャ設計・依存関係セットアップ (0.5日)

### A.1 状態管理アーキテクチャ設計

- [ ] 状態分離設計の明確化
  - [ ] **Server State (TanStack Query)**: API データ、キャッシング、同期
    - [ ] Tasks データ、User データ、Categories データ
    - [ ] バックグラウンド更新、楽観的更新
  - [ ] **Client State (Zustand)**: UI状態、フォーム、ローカルビジネスロジック
    - [ ] フィルター設定、モーダル状態、テーマ設定
    - [ ] ナビゲーション状態、一時的なフォーム状態

- [ ] ディレクトリ構造設計
  ```
  src/
  ├── stores/              # Zustand stores
  │   ├── auth-store.ts    # 認証関連のクライアント状態
  │   ├── ui-store.ts      # UI状態（モーダル、テーマなど）
  │   ├── filter-store.ts  # フィルター・ソート状態
  │   └── index.ts         # Store exports
  ├── queries/             # TanStack Query configurations
  │   ├── tasks-queries.ts # Tasks関連のquery/mutation
  │   ├── users-queries.ts # User関連のquery/mutation
  │   ├── query-keys.ts    # Query key factories
  │   └── query-client.ts  # QueryClient設定
  └── lib/
      ├── api-client.ts    # API client utilities
      └── query-utils.ts   # Query helper functions
  ```

### A.2 依存関係・パッケージセットアップ

- [ ] TanStack Query v5 導入

  ```bash
  bun add @tanstack/react-query @tanstack/react-query-devtools
  bun add -D @tanstack/eslint-plugin-query
  ```

- [ ] Zustand v5 導入

  ```bash
  bun add zustand immer
  ```

- [ ] 開発支援ツール
  ```bash
  # ESLint plugin for TanStack Query best practices
  echo '@tanstack/eslint-plugin-query' >> .eslintrc.js
  ```

### A.3 TypeScript型定義基盤

- [ ] API Response Types (`src/types/api.ts`)

  ```typescript
  // Base API Response Types
  export interface ApiResponse<T> {
    data: T;
    message?: string;
    success: boolean;
  }

  export interface PaginatedResponse<T> extends ApiResponse<T[]> {
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }

  export interface ApiError {
    message: string;
    code?: string;
    field?: string;
  }
  ```

- [ ] Store Types (`src/types/store.ts`)

  ```typescript
  // UI Store Types
  export interface UIState {
    theme: "light" | "dark" | "system";
    sidebarOpen: boolean;
    modals: {
      createTask: boolean;
      editTask: boolean;
      deleteTask: boolean;
    };
  }

  // Filter Store Types
  export interface FilterState {
    tasks: {
      status: TaskStatus | "ALL";
      priority: TaskPriority | "ALL";
      sortBy: "createdAt" | "dueDate" | "priority" | "name";
      sortOrder: "asc" | "desc";
      searchQuery: string;
    };
  }
  ```

## Phase B: TanStack Query セットアップ・設定 (1日)

### B.1 QueryClient 設定・プロバイダー

- [ ] QueryClient 設定 (`src/queries/query-client.ts`)

  ```typescript
  import { QueryClient } from "@tanstack/react-query";

  export function createQueryClient() {
    return new QueryClient({
      defaultOptions: {
        queries: {
          // Stale time: 5 minutes for most data
          staleTime: 5 * 60 * 1000,
          // Cache time: 10 minutes
          cacheTime: 10 * 60 * 1000,
          // Retry logic
          retry: (failureCount, error) => {
            // Don't retry on 4xx errors except 408, 429
            if (error?.status && error.status >= 400 && error.status < 500) {
              if (error.status === 408 || error.status === 429) {
                return failureCount < 2;
              }
              return false;
            }
            // Retry up to 3 times for other errors
            return failureCount < 3;
          },
          // Refetch on window focus in development
          refetchOnWindowFocus: process.env.NODE_ENV === "development",
        },
        mutations: {
          // Retry mutations once on failure
          retry: 1,
        },
      },
    });
  }
  ```

- [ ] App-level Provider Setup (`src/app/layout.tsx`)

  ```typescript
  'use client';

  import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
  import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
  import { useState } from 'react';

  function QueryProvider({ children }: { children: React.ReactNode }) {
    // Create QueryClient inside component to avoid sharing between users
    const [queryClient] = useState(() => createQueryClient());

    return (
      <QueryClientProvider client={queryClient}>
        {children}
        <ReactQueryDevtools initialIsOpen={false} />
      </QueryClientProvider>
    );
  }
  ```

### B.2 Query Key Factory Pattern

- [ ] Query Keys 管理 (`src/queries/query-keys.ts`)

  ```typescript
  // Query Key Factory Pattern for type safety and consistency
  export const queryKeys = {
    // User-related queries
    users: ["users"] as const,
    user: (id: string) => ["users", id] as const,
    userProfile: () => ["users", "profile"] as const,

    // Task-related queries
    tasks: ["tasks"] as const,
    tasksList: (filters: TaskFilters) => ["tasks", "list", filters] as const,
    task: (id: string) => ["tasks", id] as const,
    taskComments: (taskId: string) => ["tasks", taskId, "comments"] as const,

    // Category-related queries
    categories: ["categories"] as const,
    categoriesList: (userId: string) => ["categories", "list", userId] as const,
    category: (id: string) => ["categories", id] as const,

    // Team-related queries
    teams: ["teams"] as const,
    teamsList: (userId: string) => ["teams", "list", userId] as const,
    team: (id: string) => ["teams", id] as const,
    teamMembers: (teamId: string) => ["teams", teamId, "members"] as const,
  } as const;

  // Type-safe query key inference
  export type QueryKeys = typeof queryKeys;
  ```

### B.3 API Client Utilities

- [ ] API Client Setup (`src/lib/api-client.ts`)

  ```typescript
  import { auth } from "@/auth";

  class ApiClient {
    private baseURL: string;

    constructor() {
      this.baseURL = process.env.NEXT_PUBLIC_API_URL || "/api";
    }

    private async getAuthHeaders() {
      const session = await auth();
      return {
        "Content-Type": "application/json",
        ...(session?.accessToken && {
          Authorization: `Bearer ${session.accessToken}`,
        }),
      };
    }

    async request<T>(
      endpoint: string,
      options: RequestInit = {},
    ): Promise<ApiResponse<T>> {
      const url = `${this.baseURL}${endpoint}`;
      const headers = await this.getAuthHeaders();

      const response = await fetch(url, {
        ...options,
        headers: {
          ...headers,
          ...options.headers,
        },
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `HTTP ${response.status}`);
      }

      return response.json();
    }

    // Convenience methods
    get<T>(endpoint: string) {
      return this.request<T>(endpoint, { method: "GET" });
    }

    post<T>(endpoint: string, data?: unknown) {
      return this.request<T>(endpoint, {
        method: "POST",
        body: JSON.stringify(data),
      });
    }

    put<T>(endpoint: string, data?: unknown) {
      return this.request<T>(endpoint, {
        method: "PUT",
        body: JSON.stringify(data),
      });
    }

    delete<T>(endpoint: string) {
      return this.request<T>(endpoint, { method: "DELETE" });
    }
  }

  export const apiClient = new ApiClient();
  ```

## Phase C: Tasks用 Query/Mutation実装 (1日)

### C.1 Tasks Queries Implementation

- [ ] Tasks Query Functions (`src/queries/tasks-queries.ts`)

  ```typescript
  import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
  import { queryKeys } from "./query-keys";
  import { apiClient } from "@/lib/api-client";
  import type {
    Task,
    TaskCreateInput,
    TaskUpdateInput,
    TaskFilters,
  } from "@/types";

  // Query Functions
  export function useTasks(filters: TaskFilters = {}) {
    return useQuery({
      queryKey: queryKeys.tasksList(filters),
      queryFn: () =>
        apiClient.get<Task[]>(`/tasks?${new URLSearchParams(filters)}`),
      staleTime: 30 * 1000, // 30 seconds for tasks
    });
  }

  export function useTask(id: string) {
    return useQuery({
      queryKey: queryKeys.task(id),
      queryFn: () => apiClient.get<Task>(`/tasks/${id}`),
      enabled: !!id,
    });
  }

  // Mutation Functions with Optimistic Updates
  export function useCreateTask() {
    const queryClient = useQueryClient();

    return useMutation({
      mutationFn: (data: TaskCreateInput) =>
        apiClient.post<Task>("/tasks", data),

      onMutate: async (newTask) => {
        // Cancel outgoing refetches
        await queryClient.cancelQueries({ queryKey: queryKeys.tasks });

        // Snapshot previous value
        const previousTasks = queryClient.getQueryData(queryKeys.tasks);

        // Optimistically update cache
        queryClient.setQueryData(
          queryKeys.tasksList({}),
          (old: Task[] = []) => [
            {
              ...newTask,
              id: `temp-${Date.now()}`,
              createdAt: new Date(),
              updatedAt: new Date(),
            } as Task,
            ...old,
          ],
        );

        return { previousTasks };
      },

      onError: (err, newTask, context) => {
        // Rollback on error
        if (context?.previousTasks) {
          queryClient.setQueryData(queryKeys.tasks, context.previousTasks);
        }
      },

      onSettled: () => {
        // Refetch to ensure consistency
        queryClient.invalidateQueries({ queryKey: queryKeys.tasks });
      },
    });
  }

  export function useUpdateTask(id: string) {
    const queryClient = useQueryClient();

    return useMutation({
      mutationFn: (data: TaskUpdateInput) =>
        apiClient.put<Task>(`/tasks/${id}`, data),

      onMutate: async (updatedData) => {
        await queryClient.cancelQueries({ queryKey: queryKeys.task(id) });

        const previousTask = queryClient.getQueryData(queryKeys.task(id));

        queryClient.setQueryData(queryKeys.task(id), (old: Task) => ({
          ...old,
          ...updatedData,
          updatedAt: new Date(),
        }));

        return { previousTask };
      },

      onError: (err, updatedData, context) => {
        if (context?.previousTask) {
          queryClient.setQueryData(queryKeys.task(id), context.previousTask);
        }
      },

      onSettled: () => {
        queryClient.invalidateQueries({ queryKey: queryKeys.task(id) });
        queryClient.invalidateQueries({ queryKey: queryKeys.tasks });
      },
    });
  }

  export function useDeleteTask() {
    const queryClient = useQueryClient();

    return useMutation({
      mutationFn: (id: string) => apiClient.delete(`/tasks/${id}`),

      onMutate: async (deletedId) => {
        await queryClient.cancelQueries({ queryKey: queryKeys.tasks });

        const previousTasks = queryClient.getQueryData(queryKeys.tasks);

        queryClient.setQueryData(queryKeys.tasksList({}), (old: Task[] = []) =>
          old.filter((task) => task.id !== deletedId),
        );

        return { previousTasks, deletedId };
      },

      onError: (err, deletedId, context) => {
        if (context?.previousTasks) {
          queryClient.setQueryData(queryKeys.tasks, context.previousTasks);
        }
      },

      onSuccess: (_, deletedId) => {
        // Remove individual task from cache
        queryClient.removeQueries({ queryKey: queryKeys.task(deletedId) });
      },

      onSettled: () => {
        queryClient.invalidateQueries({ queryKey: queryKeys.tasks });
      },
    });
  }
  ```

### C.2 Background Synchronization設定

- [ ] Refetch Strategies (`src/queries/tasks-queries.ts` 拡張)
  ```typescript
  // Background refetch configuration
  export function useTasksWithSync(filters: TaskFilters = {}) {
    return useQuery({
      queryKey: queryKeys.tasksList(filters),
      queryFn: () =>
        apiClient.get<Task[]>(`/tasks?${new URLSearchParams(filters)}`),
      staleTime: 30 * 1000,
      // Refetch every 2 minutes when window is focused
      refetchInterval: 2 * 60 * 1000,
      refetchIntervalInBackground: false,
      // Refetch on reconnect
      refetchOnReconnect: true,
      // Refetch on mount if data is stale
      refetchOnMount: true,
    });
  }
  ```

## Phase D: Zustand Client State Management (1日)

### D.1 UI State Store

- [ ] UI Store Implementation (`src/stores/ui-store.ts`)

  ```typescript
  import { create } from "zustand";
  import { devtools, persist } from "zustand/middleware";
  import { immer } from "zustand/middleware/immer";

  interface UIState {
    // Theme management
    theme: "light" | "dark" | "system";
    setTheme: (theme: "light" | "dark" | "system") => void;

    // Sidebar state
    sidebarOpen: boolean;
    setSidebarOpen: (open: boolean) => void;
    toggleSidebar: () => void;

    // Modal states
    modals: {
      createTask: boolean;
      editTask: string | null; // Task ID being edited
      deleteTask: string | null; // Task ID being deleted
      createCategory: boolean;
      taskDetails: string | null; // Task ID for details modal
    };
    openModal: (modal: keyof UIState["modals"], data?: string) => void;
    closeModal: (modal: keyof UIState["modals"]) => void;
    closeAllModals: () => void;

    // Loading states
    isLoading: Record<string, boolean>;
    setLoading: (key: string, loading: boolean) => void;
  }

  export const useUIStore = create<UIState>()(
    devtools(
      persist(
        immer((set) => ({
          // Initial state
          theme: "system",
          sidebarOpen: false,
          modals: {
            createTask: false,
            editTask: null,
            deleteTask: null,
            createCategory: false,
            taskDetails: null,
          },
          isLoading: {},

          // Actions
          setTheme: (theme) =>
            set((state) => {
              state.theme = theme;
            }),

          setSidebarOpen: (open) =>
            set((state) => {
              state.sidebarOpen = open;
            }),

          toggleSidebar: () =>
            set((state) => {
              state.sidebarOpen = !state.sidebarOpen;
            }),

          openModal: (modal, data) =>
            set((state) => {
              if (data && typeof state.modals[modal] === "string") {
                state.modals[modal] = data;
              } else {
                state.modals[modal] = true;
              }
            }),

          closeModal: (modal) =>
            set((state) => {
              state.modals[modal] =
                typeof state.modals[modal] === "string" ? null : false;
            }),

          closeAllModals: () =>
            set((state) => {
              Object.keys(state.modals).forEach((key) => {
                const modalKey = key as keyof UIState["modals"];
                state.modals[modalKey] =
                  typeof state.modals[modalKey] === "string" ? null : false;
              });
            }),

          setLoading: (key, loading) =>
            set((state) => {
              if (loading) {
                state.isLoading[key] = true;
              } else {
                delete state.isLoading[key];
              }
            }),
        })),
        {
          name: "ui-store",
          partialize: (state) => ({
            theme: state.theme,
            sidebarOpen: state.sidebarOpen,
          }),
        },
      ),
      { name: "UI Store" },
    ),
  );
  ```

### D.2 Filter State Store

- [ ] Filter Store Implementation (`src/stores/filter-store.ts`)

  ```typescript
  import { create } from "zustand";
  import { devtools } from "zustand/middleware";
  import { immer } from "zustand/middleware/immer";
  import type { TaskStatus, TaskPriority } from "@/types";

  interface FilterState {
    tasks: {
      status: TaskStatus | "ALL";
      priority: TaskPriority | "ALL";
      sortBy: "createdAt" | "dueDate" | "priority" | "name";
      sortOrder: "asc" | "desc";
      searchQuery: string;
      showCompleted: boolean;
    };
    categories: {
      searchQuery: string;
      sortBy: "name" | "createdAt" | "taskCount";
      sortOrder: "asc" | "desc";
    };
  }

  interface FilterActions {
    // Task filters
    setTaskFilter: <K extends keyof FilterState["tasks"]>(
      key: K,
      value: FilterState["tasks"][K],
    ) => void;
    resetTaskFilters: () => void;
    getTaskFiltersAsParams: () => Record<string, string>;

    // Category filters
    setCategoryFilter: <K extends keyof FilterState["categories"]>(
      key: K,
      value: FilterState["categories"][K],
    ) => void;
    resetCategoryFilters: () => void;
  }

  const initialTaskFilters: FilterState["tasks"] = {
    status: "ALL",
    priority: "ALL",
    sortBy: "createdAt",
    sortOrder: "desc",
    searchQuery: "",
    showCompleted: true,
  };

  const initialCategoryFilters: FilterState["categories"] = {
    searchQuery: "",
    sortBy: "name",
    sortOrder: "asc",
  };

  export const useFilterStore = create<FilterState & FilterActions>()(
    devtools(
      immer((set, get) => ({
        // Initial state
        tasks: initialTaskFilters,
        categories: initialCategoryFilters,

        // Task filter actions
        setTaskFilter: (key, value) =>
          set((state) => {
            state.tasks[key] = value;
          }),

        resetTaskFilters: () =>
          set((state) => {
            state.tasks = initialTaskFilters;
          }),

        getTaskFiltersAsParams: () => {
          const filters = get().tasks;
          const params: Record<string, string> = {};

          if (filters.status !== "ALL") params.status = filters.status;
          if (filters.priority !== "ALL") params.priority = filters.priority;
          if (filters.searchQuery) params.search = filters.searchQuery;
          if (!filters.showCompleted) params.showCompleted = "false";

          params.sortBy = filters.sortBy;
          params.sortOrder = filters.sortOrder;

          return params;
        },

        // Category filter actions
        setCategoryFilter: (key, value) =>
          set((state) => {
            state.categories[key] = value;
          }),

        resetCategoryFilters: () =>
          set((state) => {
            state.categories = initialCategoryFilters;
          }),
      })),
      { name: "Filter Store" },
    ),
  );
  ```

### D.3 Form State Store (temporary form data)

- [ ] Form Store Implementation (`src/stores/form-store.ts`)

  ```typescript
  import { create } from "zustand";
  import { devtools } from "zustand/middleware";
  import { immer } from "zustand/middleware/immer";
  import type { TaskCreateInput, TaskUpdateInput } from "@/types";

  interface FormState {
    // Task form data (for auto-save, draft functionality)
    taskForm: {
      draft: Partial<TaskCreateInput>;
      isDirty: boolean;
    };

    // Category form data
    categoryForm: {
      draft: { name: string; description?: string };
      isDirty: boolean;
    };
  }

  interface FormActions {
    // Task form actions
    setTaskFormDraft: (draft: Partial<TaskCreateInput>) => void;
    clearTaskFormDraft: () => void;
    setTaskFormDirty: (isDirty: boolean) => void;

    // Category form actions
    setCategoryFormDraft: (draft: {
      name: string;
      description?: string;
    }) => void;
    clearCategoryFormDraft: () => void;
    setCategoryFormDirty: (isDirty: boolean) => void;

    // Clear all forms
    clearAllForms: () => void;
  }

  export const useFormStore = create<FormState & FormActions>()(
    devtools(
      immer((set) => ({
        // Initial state
        taskForm: {
          draft: {},
          isDirty: false,
        },
        categoryForm: {
          draft: { name: "" },
          isDirty: false,
        },

        // Task form actions
        setTaskFormDraft: (draft) =>
          set((state) => {
            state.taskForm.draft = draft;
            state.taskForm.isDirty = Object.keys(draft).length > 0;
          }),

        clearTaskFormDraft: () =>
          set((state) => {
            state.taskForm.draft = {};
            state.taskForm.isDirty = false;
          }),

        setTaskFormDirty: (isDirty) =>
          set((state) => {
            state.taskForm.isDirty = isDirty;
          }),

        // Category form actions
        setCategoryFormDraft: (draft) =>
          set((state) => {
            state.categoryForm.draft = draft;
            state.categoryForm.isDirty = draft.name.length > 0;
          }),

        clearCategoryFormDraft: () =>
          set((state) => {
            state.categoryForm.draft = { name: "" };
            state.categoryForm.isDirty = false;
          }),

        setCategoryFormDirty: (isDirty) =>
          set((state) => {
            state.categoryForm.isDirty = isDirty;
          }),

        // Clear all forms
        clearAllForms: () =>
          set((state) => {
            state.taskForm = { draft: {}, isDirty: false };
            state.categoryForm = { draft: { name: "" }, isDirty: false };
          }),
      })),
      { name: "Form Store" },
    ),
  );
  ```

## Phase E: 統合・テスト・ドキュメント (0.5日)

### E.1 Integration Testing

- [ ] Store Integration Test (`src/stores/__tests__/integration.test.ts`)

  ```typescript
  import { renderHook, act } from "@testing-library/react";
  import { useUIStore } from "../ui-store";
  import { useFilterStore } from "../filter-store";

  describe("Store Integration", () => {
    beforeEach(() => {
      // Reset stores before each test
      useUIStore.setState(useUIStore.getState(), true);
      useFilterStore.setState(useFilterStore.getState(), true);
    });

    it("should manage modal and filter states independently", () => {
      const { result: uiResult } = renderHook(() => useUIStore());
      const { result: filterResult } = renderHook(() => useFilterStore());

      act(() => {
        uiResult.current.openModal("createTask");
        filterResult.current.setTaskFilter("status", "TODO");
      });

      expect(uiResult.current.modals.createTask).toBe(true);
      expect(filterResult.current.tasks.status).toBe("TODO");
    });
  });
  ```

- [ ] TanStack Query Integration Test
  ```typescript
  // Test optimistic updates and cache invalidation
  ```

### E.2 Performance Optimization

- [ ] Query Performance Config

  ```typescript
  // Configure selective re-rendering
  export function useTasksOptimized(filters: TaskFilters) {
    return useQuery({
      queryKey: queryKeys.tasksList(filters),
      queryFn: () => apiClient.get<Task[]>("/tasks", { params: filters }),
      select: useCallback((data: ApiResponse<Task[]>) => data.data, []),
      // Only re-render when actual data changes
      structuralSharing: true,
    });
  }
  ```

- [ ] Zustand Selector Optimization

  ```typescript
  // Prevent unnecessary re-renders with shallow equality
  import { shallow } from "zustand/shallow";

  export function useTaskFilters() {
    return useFilterStore(
      (state) => ({
        filters: state.tasks,
        setFilter: state.setTaskFilter,
        reset: state.resetTaskFilters,
      }),
      shallow,
    );
  }
  ```

### E.3 Developer Experience Enhancement

- [ ] Store Devtools Setup

  ```typescript
  // Redux DevTools Extension integration for Zustand
  // TanStack Query DevTools for query inspection
  ```

- [ ] Custom Hooks Documentation (`docs/state-management-guide.md`)

  ````markdown
  # State Management Guide

  ## Architecture Overview

  - **Server State**: TanStack Query for API data
  - **Client State**: Zustand for UI and local state

  ## Usage Patterns

  ### Data Fetching

  ```typescript
  const { data: tasks, isLoading } = useTasks({ status: "TODO" });
  ```
  ````

  ### UI State Management

  ```typescript
  const { openModal, closeModal } = useUIStore();
  ```

  ```

  ```

## 完了判定基準

### 技術的成功条件

- [ ] TanStack Query が正常にセットアップされ、DevTools が動作する
- [ ] Zustand stores が適切に設定され、状態管理が機能する
- [ ] Query/Mutation の楽観的更新が正常動作する
- [ ] TypeScript型エラーがない
- [ ] ESLint エラーがない (TanStack Query rules含む)
- [ ] パフォーマンステスト: 不要な再レンダリングがない

### Phase 3 開発準備完了条件

- [ ] `useTasks()`, `useCreateTask()`, `useUpdateTask()`, `useDeleteTask()` が利用可能
- [ ] UI状態 (modals, filters) の管理パターンが確立
- [ ] API エラーハンドリング・楽観的更新パターンが確立
- [ ] 従来のuseState/useEffectベースのパターンから完全移行

## 推定工数・スケジュール

| Phase    | 作業内容                        | 推定工数 | 担当者 |
| -------- | ------------------------------- | -------- | ------ |
| Phase A  | アーキテクチャ設計・依存関係    | 0.5日    | hep    |
| Phase B  | TanStack Query セットアップ     | 1日      | hep    |
| Phase C  | Tasks Query/Mutation実装        | 1日      | hep    |
| Phase D  | Zustand Client State Management | 1日      | hep    |
| Phase E  | 統合・テスト・ドキュメント      | 0.5日    | hep    |
| **合計** | **全プロセス**                  | **4日**  | -      |

## Phase 3以降への影響・メリット

### 開発効率向上

- **従来パターン**: 各コンポーネントで個別のAPI呼び出し、手動キャッシング
- **新パターン**: 宣言的データ取得、自動キャッシング、楽観的更新

### UX向上

- **即座のUI更新**: 楽観的更新によるレスポンシブな操作感
- **背景同期**: 最新データの自動取得・表示
- **エラー処理**: 統一されたエラーハンドリングとロールバック

### 保守性向上

- **状態の一元管理**: Server/Client状態の明確な分離
- **型安全性**: TypeScriptによる完全な型チェック
- **テスタビリティ**: 分離されたロジックによる簡単なテスト

---

**Phase 2c 優先度**: MUST  
**実装価値**: VERY HIGH（全Phase機能の品質・効率・保守性の根本的改善）  
**完了条件**: Phase 3以降でTanStack Query + Zustand統合パターンが使用可能な状態
