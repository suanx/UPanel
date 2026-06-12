import { createRouter, createWebHashHistory } from 'vue-router'

const isAuthenticated = () => {
  return !!localStorage.getItem('token')
}

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/auth/Login.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('@/views/Dashboard.vue'), meta: { title: '总览' } },
      { path: 'containers', component: () => import('@/views/Containers.vue'), meta: { title: '容器管理' } },
      { path: 'apps', component: () => import('@/views/Apps.vue'), meta: { title: '应用商店' } },
      { path: 'websites', component: () => import('@/views/Websites.vue'), meta: { title: '网站' } },
      { path: 'databases', component: () => import('@/views/Databases.vue'), meta: { title: '数据库' } },
      { path: 'files', component: () => import('@/views/Files.vue'), meta: { title: '文件管理' } },
      { path: 'monitor', component: () => import('@/views/monitor/Index.vue'), meta: { title: '监控' } },
      { path: 'ssh', component: () => import('@/views/Ssh.vue'), meta: { title: 'SSH管理' } },
      { path: 'security', component: () => import('@/views/Security.vue'), meta: { title: '安全设置' } },
      { path: 'email-notify', component: () => import('@/views/toolbox/EmailNotify.vue'), meta: { title: '邮件通知' } },
      { path: 'cron', component: () => import('@/views/Cron.vue'), meta: { title: '计划任务' } },
      { path: 'settings', component: () => import('@/views/Settings.vue'), meta: { title: '面板设置' } },
      { path: 'logout', component: () => import('@/views/Logout.vue'), meta: { title: '退出面板' } }
    ]
  },
  // 未知路径重定向到登录页
  { path: '/:pathMatch(.*)*', redirect: '/login' }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  if (to.path === '/login' && isAuthenticated()) {
    next('/')
    return
  }
  if (to.meta.requiresAuth && !isAuthenticated()) {
    next('/login')
    return
  }
  next()
})

export default router

// 在路由守卫中重新应用主题
router.afterEach(() => {
  const saved = localStorage.getItem('theme')
  if (saved === 'davinci') {
    import('@/themes').then(({ applyTheme }) => {
      applyTheme('davinci')
    })
  }
})
