<template>
  <div class="app-container">
    <div class="mobile-overlay" v-if="mobileSidebarOpen" @click="closeMobileSidebar"></div> :class="{ 'sidebar-collapsed': isCollapsed, 'mobile-sidebar-open': mobileSidebarOpen }">
    <!-- a 面板：左侧菜单 -->
    <aside class="sidebar" :class="{ 'sidebar-show': mobileSidebarOpen }">
      <div class="mobile-close-btn" @click="closeMobileSidebar">
        <el-icon :size="22"><Close /></el-icon>
      </div>
      <div class="logo-area" :class="{ 'logo-collapsed': isCollapsed }">
        <h1 v-if="!isCollapsed" class="logo">UPanel</h1>
        <h1 v-else class="logo-mini">UP</h1>
        <p v-if="!isCollapsed" class="logo-sub">轻量级容器面板</p>
      </div>
      
      <nav class="menu">
        <!-- 主菜单（根据显示配置过滤） -->
        <div v-for="item in visibleMainMenus" :key="item.path" class="menu-item" :class="{ active: isActive(item.path) }" @click="navigateMobile(item.path)">
          <el-icon class="menu-icon"><component :is="item.icon" /></el-icon>
          <span v-if="!isCollapsed" class="menu-text">{{ item.name }}</span>
        </div>
        
        <!-- 主机子菜单 -->
        <div v-if="showHostInMenu" class="menu-group">
          <div class="menu-item" :class="{ active: isHostActive }" @click="toggleHostMenu">
            <el-icon class="menu-icon"><Monitor /></el-icon>
            <span v-if="!isCollapsed" class="menu-text">主机</span>
            <el-icon v-if="!isCollapsed" class="menu-arrow"><ArrowDown v-if="!showHostMenu" /><ArrowUp v-else /></el-icon>
          </div>
          <div v-show="showHostMenu && !isCollapsed" class="submenu">
            <div v-if="showFilesInMenu" class="submenu-item" :class="{ active: $route.path === '/files' }" @click="navigate('/files')">文件</div>
            <div v-if="showMonitorInMenu" class="submenu-item" :class="{ active: $route.path === '/monitor' }" @click="navigate('/monitor')">监控</div>
            <div v-if="showSshInMenu" class="submenu-item" :class="{ active: $route.path === '/ssh' }" @click="navigate('/ssh')">SSH</div>
            <div v-if="showSecurityInMenu" class="submenu-item" :class="{ active: $route.path === '/security' }" @click="navigate('/security')">安全</div>
          </div>
        </div>

        <!-- 工具箱子菜单 -->
        <div v-if="showToolboxInMenu" class="menu-group">
          <div class="menu-item" :class="{ active: isToolboxActive }" @click="toggleToolboxMenu">
            <el-icon class="menu-icon"><Tools /></el-icon>
            <span v-if="!isCollapsed" class="menu-text">工具箱</span>
            <el-icon v-if="!isCollapsed" class="menu-arrow"><ArrowDown v-if="!showToolboxMenu" /><ArrowUp v-else /></el-icon>
          </div>
          <div v-show="showToolboxMenu && !isCollapsed" class="submenu">
            <div v-if="showEmailInMenu" class="submenu-item" :class="{ active: $route.path === '/email-notify' }" @click="navigate('/email-notify')">邮件通知</div>
          </div>
        </div>
        
        <!-- 底部菜单（根据显示配置过滤） -->
        <div v-for="item in visibleBottomMenus" :key="item.path" class="menu-item" :class="{ active: isActive(item.path) }" @click="navigateMobile(item.path)">
          <el-icon class="menu-icon"><component :is="item.icon" /></el-icon>
          <span v-if="!isCollapsed" class="menu-text">{{ item.name }}</span>
        </div>
      </nav>
      
      <!-- 底部工具栏 -->
      <div class="sidebar-footer">
        <!-- 折叠按钮 -->
        <div class="footer-btn desktop-only" @click="toggleCollapse" :title="isCollapsed ? '展开菜单' : '收起菜单'">
          <el-icon :size="18">
            <DArrowLeft v-if="!isCollapsed" />
            <DArrowRight v-else />
          </el-icon>
          <span v-if="!isCollapsed" class="footer-btn-text">收起菜单</span>
        </div>
        
        <!-- 菜单配置按钮 -->
        <div class="footer-btn" @click="showMenuConfig = true" :title="isCollapsed ? '菜单配置' : '配置菜单'">
          <el-icon :size="18"><Setting /></el-icon>
          <span v-if="!isCollapsed" class="footer-btn-text">菜单配置</span>
        </div>
      </div>
    </aside>
    
    <div class="main-area">
      <header class="top-bar">
        <h2 class="page-title">{{ currentTitle }}</h2>
        <div class="user-info">
          <el-dropdown @command="handleCommand">
            <span class="user-name">{{ username }} <el-icon><ArrowDown /></el-icon></span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="settings">面板设置</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>
      
      <main class="content-area">
        <router-view />
      </main>
      
      <footer class="footer">
        <span>UPanel 开源容器面板</span>
        <a href="https://github.com/likeweixue/UPanel" target="_blank" class="footer-link desktop-only">GitHub</a>
        <span class="footer-version">v0.1.5</span>
      </footer>
    </div>

    <!-- 菜单配置对话框 -->
    <el-dialog v-model="showMenuConfig" title="菜单配置" width="400px">
      <div class="menu-config">
        <div class="config-section">
          <div class="config-title">主菜单</div>
          <el-checkbox-group v-model="visibleMainMenusKeys">
            <div v-for="item in allMainMenus" :key="item.path" class="config-item">
              <el-checkbox :value="item.path">{{ item.name }}</el-checkbox>
            </div>
          </el-checkbox-group>
        </div>
        
        <div class="config-section">
          <div class="config-title">主机菜单</div>
          <el-checkbox v-model="showHostInMenu">显示主机菜单</el-checkbox>
          <div class="config-sub" v-if="showHostInMenu">
            <el-checkbox-group v-model="visibleHostSubKeys">
              <div v-for="item in hostSubMenus" :key="item.path" class="config-item">
                <el-checkbox :value="item.path">{{ item.name }}</el-checkbox>
              </div>
            </el-checkbox-group>
          </div>
        </div>
        
        <div class="config-section">
          <div class="config-title">工具箱菜单</div>
          <el-checkbox v-model="showToolboxInMenu">显示工具箱菜单</el-checkbox>
          <div class="config-sub" v-if="showToolboxInMenu">
            <el-checkbox-group v-model="visibleToolboxSubKeys">
              <div v-for="item in toolboxSubMenus" :key="item.path" class="config-item">
                <el-checkbox :value="item.path">{{ item.name }}</el-checkbox>
              </div>
            </el-checkbox-group>
          </div>
        </div>
        
        <div class="config-section">
          <div class="config-title">底部菜单</div>
          <el-checkbox-group v-model="visibleBottomMenusKeys">
            <div v-for="item in allBottomMenus" :key="item.path" class="config-item">
              <el-checkbox :value="item.path">{{ item.name }}</el-checkbox>
            </div>
          </el-checkbox-group>
        </div>
      </div>
      <template #footer>
        <el-button @click="showMenuConfig = false">取消</el-button>
        <el-button type="primary" @click="saveMenuConfig">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Monitor, DataBoard, Shop, Setting, SwitchButton, ArrowDown, ArrowUp, Grid, Coin, Calendar, Odometer, Tools, DArrowLeft, DArrowRight, Expand, Fold, Close } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const username = ref('admin')
const showHostMenu = ref(false)
const showToolboxMenu = ref(false)
const showMenuConfig = ref(false)

// 折叠状态
const isCollapsed = ref(false)
const mobileSidebarOpen = ref(false)
const isMobile = ref(false)

// 所有菜单定义
const allMainMenus = [
  { path: '/dashboard', name: '总览', icon: Odometer },
  { path: '/apps', name: '应用商店', icon: Shop },
  { path: '/websites', name: '网站', icon: Grid },
  { path: '/databases', name: '数据库', icon: Coin },
  { path: '/containers', name: '容器', icon: DataBoard }
]

const allBottomMenus = [
  { path: '/cron', name: '计划任务', icon: Calendar },
  { path: '/settings', name: '面板设置', icon: Setting },
  { path: '/logout', name: '退出', icon: SwitchButton }
]

const hostSubMenus = [
  { path: '/files', name: '文件' },
  { path: '/monitor', name: '监控' },
  { path: '/ssh', name: 'SSH' },
  { path: '/security', name: '安全' }
]

const toolboxSubMenus = [
  { path: '/email-notify', name: '邮件通知' }
]

// 可见菜单的 keys
const visibleMainMenusKeys = ref([])
const visibleBottomMenusKeys = ref([])
const visibleHostSubKeys = ref([])
const visibleToolboxSubKeys = ref([])
const showHostInMenu = ref(true)
const showToolboxInMenu = ref(true)

// 加载菜单配置
const loadMenuConfig = () => {
  const saved = localStorage.getItem('menuConfig')
  if (saved) {
    try {
      const config = JSON.parse(saved)
      visibleMainMenusKeys.value = config.mainMenus || allMainMenus.map(m => m.path)
      visibleBottomMenusKeys.value = config.bottomMenus || allBottomMenus.map(m => m.path)
      visibleHostSubKeys.value = config.hostSubMenus || hostSubMenus.map(m => m.path)
      visibleToolboxSubKeys.value = config.toolboxSubMenus || toolboxSubMenus.map(m => m.path)
      showHostInMenu.value = config.showHost !== undefined ? config.showHost : true
      showToolboxInMenu.value = config.showToolbox !== undefined ? config.showToolbox : true
    } catch (e) {}
  } else {
    // 默认全部显示
    visibleMainMenusKeys.value = allMainMenus.map(m => m.path)
    visibleBottomMenusKeys.value = allBottomMenus.map(m => m.path)
    visibleHostSubKeys.value = hostSubMenus.map(m => m.path)
    visibleToolboxSubKeys.value = toolboxSubMenus.map(m => m.path)
  }
}

// 保存菜单配置
const saveMenuConfig = () => {
  const config = {
    mainMenus: visibleMainMenusKeys.value,
    bottomMenus: visibleBottomMenusKeys.value,
    hostSubMenus: visibleHostSubKeys.value,
    toolboxSubMenus: visibleToolboxSubKeys.value,
    showHost: showHostInMenu.value,
    showToolbox: showToolboxInMenu.value
  }
  localStorage.setItem('menuConfig', JSON.stringify(config))
  showMenuConfig.value = false
  ElMessage.success('菜单配置已保存')
}

// 计算可见菜单
const visibleMainMenus = computed(() => {
  return allMainMenus.filter(m => visibleMainMenusKeys.value.includes(m.path))
})

const visibleBottomMenus = computed(() => {
  return allBottomMenus.filter(m => visibleBottomMenusKeys.value.includes(m.path))
})

const visibleHostSubMenus = computed(() => {
  return hostSubMenus.filter(m => visibleHostSubKeys.value.includes(m.path))
})

const visibleToolboxSubMenus = computed(() => {
  return toolboxSubMenus.filter(m => visibleToolboxSubKeys.value.includes(m.path))
})

// 主机子菜单显示条件
const showFilesInMenu = computed(() => visibleHostSubKeys.value.includes('/files'))
const showMonitorInMenu = computed(() => visibleHostSubKeys.value.includes('/monitor'))
const showSshInMenu = computed(() => visibleHostSubKeys.value.includes('/ssh'))
const showSecurityInMenu = computed(() => visibleHostSubKeys.value.includes('/security'))
const showEmailInMenu = computed(() => visibleToolboxSubKeys.value.includes('/email-notify'))

// 加载折叠状态
const loadCollapseState = () => {
  const saved = localStorage.getItem('sidebarCollapsed')
  if (saved !== null) {
    isCollapsed.value = saved === 'true'
  }
}

const saveCollapseState = (collapsed) => {
  localStorage.setItem('sidebarCollapsed', collapsed)
}

const toggleMobileSidebar = () => { mobileSidebarOpen.value = !mobileSidebarOpen.value }
const closeMobileSidebar = () => { mobileSidebarOpen.value = false }

const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
  saveCollapseState(isCollapsed.value)
  setTimeout(() => window.dispatchEvent(new Event('resize')), 300)
}

const mainMenus = visibleMainMenus
const bottomMenus = visibleBottomMenus

const currentTitle = computed(() => {
  const all = [...visibleMainMenus.value, ...visibleBottomMenus.value]
  const found = all.find(m => route.path.includes(m.path))
  if (found) return found.name
  if (route.path === '/monitor') return '监控'
  if (route.path === '/files') return '文件管理'
  if (route.path === '/ssh') return 'SSH管理'
  if (route.path === '/security') return '安全设置'
  if (route.path === '/email-notify') return '邮件通知'
  return '总览'
})

const isActive = (path) => route.path.includes(path)
const isHostActive = computed(() => ['/files', '/monitor', '/ssh', '/security'].includes(route.path))
const isToolboxActive = computed(() => ['/email-notify'].includes(route.path))

const toggleHostMenu = () => { showHostMenu.value = !showHostMenu.value }
const toggleToolboxMenu = () => { showToolboxMenu.value = !showToolboxMenu.value }
const navigate = (path) => { router.push(path) }
const navigateMobile = (path) => { closeMobileSidebar(); router.push(path) }
const handleCommand = (command) => {
  if (command === 'settings') router.push('/settings')
  else if (command === 'logout') router.push('/logout')
}

const checkMobile = () => { isMobile.value = window.innerWidth < 768; if (!isMobile.value) mobileSidebarOpen.value = false; }

onMounted(() => {
  loadCollapseState()
  loadMenuConfig()
})
</script>

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body, #app { width: 100%; height: 100%; overflow: hidden; }
</style>

<style scoped>
.app-container { display: flex; width: 100%; height: 100%; background-color: #f1f1f1; overflow: hidden; transition: all 0.3s ease; }

/* 侧边栏 */
.sidebar { 
  width: 220px; 
  background-color: #ffffff; 
  display: flex; 
  flex-direction: column; 
  flex-shrink: 0; 
  height: 100%; 
  overflow-y: auto; 
  border-right: 1px solid #e5e7eb;
  transition: width 0.3s ease;
  position: relative;
}

.sidebar-collapsed .sidebar { width: 64px; }
.sidebar-collapsed .menu-text,
.sidebar-collapsed .logo-sub,
.sidebar-collapsed .menu-arrow,
.sidebar-collapsed .footer-btn-text { display: none; }
.sidebar-collapsed .menu-item { justify-content: center; padding: 10px 0; }
.sidebar-collapsed .menu-icon { margin-right: 0; font-size: 20px; }
.sidebar-collapsed .submenu { display: none; }

.logo-area {
  padding: 20px 16px;
  text-align: center;
  border-bottom: 1px solid #e5e7eb;
  transition: all 0.3s ease;
}
.logo-collapsed { padding: 20px 0; }
.logo { font-size: 18px; font-weight: bold; color: #477779; margin: 0; }
.logo-mini { font-size: 16px; font-weight: bold; color: #477779; margin: 0; }
.logo-sub { font-size: 12px; color: #9ca3af; margin-top: 4px; }

.menu { flex: 1; padding: 12px 8px; }
.menu-item {
  display: flex;
  align-items: center;
  padding: 10px 12px;
  margin-bottom: 2px;
  border-radius: 6px;
  cursor: pointer;
  color: #4b5563;
  transition: all 0.2s;
}
.menu-item:hover { background-color: #f3f4f6; }
.menu-item.active { background-color: #477779; color: white; }
.menu-icon { font-size: 18px; margin-right: 10px; flex-shrink: 0; }
.menu-text { font-size: 13px; font-weight: 500; flex: 1; }
.menu-arrow { font-size: 12px; margin-left: 4px; }

.submenu { padding-left: 40px; margin-bottom: 4px; }
.submenu-item {
  padding: 8px 12px;
  margin-bottom: 2px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  color: #6b7280;
}
.submenu-item:hover { background-color: #f3f4f6; color: #477779; }
.submenu-item.active { background-color: #e8f4f4; color: #477779; font-weight: 500; }

/* 底部工具栏 */
.sidebar-footer {
  padding: 12px 8px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.footer-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 8px 12px;
  cursor: pointer;
  color: #6b7280;
  transition: all 0.2s;
  border-radius: 6px;
}

.footer-btn:hover {
  background-color: #f3f4f6;
  color: #477779;
}

.footer-btn-text {
  font-size: 12px;
}

.sidebar-collapsed .footer-btn {
  padding: 8px 0;
}

/* 右侧区域 */
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
  min-width: 0;
  overflow: hidden;
}
.top-bar {
  background-color: #ffffff;
  padding: 12px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}
.page-title { font-size: 18px; font-weight: 600; color: #1f2937; margin: 0; }
.user-name { cursor: pointer; display: flex; align-items: center; gap: 4px; color: #4b5563; font-size: 13px; }
.content-area { flex: 1; overflow-y: auto; padding: 20px; min-height: 0; }
.footer {
  background-color: #ffffff;
  padding: 8px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11px;
  color: #9ca3af;
  border-top: 1px solid #e5e7eb;
  flex-shrink: 0;
}
.footer-link { color: #477779; text-decoration: none; }
.footer-link:hover { text-decoration: underline; }
.footer-version { margin-left: auto; }

/* 菜单配置对话框 */
.menu-config { max-height: 500px; overflow-y: auto; }
.config-section { margin-bottom: 20px; }
.config-title { font-size: 14px; font-weight: 600; color: #1f2937; margin-bottom: 10px; padding-bottom: 5px; border-bottom: 1px solid #e5e7eb; }
.config-sub { margin-left: 20px; margin-top: 10px; }
.config-item { margin: 8px 0; }

/* 暗色模式 */
body.dark-mode .sidebar,
body.dark-mode .top-bar,
body.dark-mode .footer {
  background-color: #1e1e1e;
  border-color: #2a2a2a;
}
body.dark-mode .sidebar-footer { border-top-color: #2a2a2a; }
body.dark-mode .footer-btn:hover { background-color: #2a2a2a; }
body.dark-mode .config-title { color: #e5e7eb; border-bottom-color: #2a2a2a; }

/* 移动端 */
.mobile-close-btn, .mobile-overlay { display: none; }

@media (max-width: 767px) {
  .sidebar { position: fixed; left: -260px; top: 0; bottom: 0; width: 240px !important; z-index: 1001; transition: left 0.3s ease; box-shadow: 4px 0 20px rgba(0,0,0,0.15); }
  .sidebar.sidebar-show { left: 0; }
  .mobile-overlay { display: block; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000; }
  .mobile-close-btn { display: flex; justify-content: flex-end; padding: 12px 16px 0; cursor: pointer; color: #6b7280; }
  .mobile-close-btn:hover { color: #477779; }
  .desktop-only { display: none !important; }
  .sidebar-footer .footer-btn { justify-content: flex-start !important; padding: 8px 12px !important; }
  .mobile-hamburger { display: flex; align-items: center; cursor: pointer; color: #4b5563; margin-right: 12px; }
  .top-bar { padding: 12px 16px; }
  .content-area { padding: 12px; overflow-x: hidden; }
  .page-title { font-size: 16px; }
  .footer { padding: 8px 16px; font-size: 10px; }
  body.dark-mode .sidebar { background-color: #1e1e1e; box-shadow: 4px 0 20px rgba(0,0,0,0.4); }
  body.dark-mode .mobile-hamburger { color: #9ca3af; }
  body.dark-mode .mobile-hamburger:hover { color: #7a9fa1; }
  body.dark-mode .mobile-close-btn { color: #9ca3af; }
  body.dark-mode .mobile-close-btn:hover { color: #7a9fa1; }
}
</style>
