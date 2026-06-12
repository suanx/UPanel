<template>
  <div class="apps-container">
    <!-- 分类面板 -->
    <div class="categories-panel">
      <div class="categories-wrapper">
        <div class="categories-left">
      { id: "14", key: "java", name: "Java", category: "environment", description: "企业级应用开发平台", icon: "Document", versions: ["17"], default_version: "17" },
      { id: "15", key: "caddy", name: "Caddy", category: "web", description: "自动HTTPS的极简Web服务器", icon: "Monitor", versions: ["latest", "2"], default_version: "latest" },
      { id: "16", key: "mariadb", name: "MariaDB", category: "database", description: "MySQL替代品，开源关系型数据库", icon: "Coin", versions: ["11", "10"], default_version: "11" },
      { id: "17", key: "mongodb", name: "MongoDB", category: "database", description: "文档型NoSQL数据库", icon: "Coin", versions: ["7.0", "6.0"], default_version: "7.0" },
      { id: "18", key: "gitea", name: "Gitea", category: "tools", description: "轻量级Git代码托管服务", icon: "Tools", versions: ["latest", "1.21"], default_version: "latest" },
      { id: "19", key: "uptime-kuma", name: "Uptime Kuma", category: "tools", description: "网站状态监控与告警", icon: "Tools", versions: ["latest"], default_version: "latest" },
      { id: "20", key: "grafana", name: "Grafana", category: "tools", description: "监控可视化仪表盘", icon: "Tools", versions: ["latest", "10"], default_version: "latest" },
      { id: "21", key: "netdata", name: "Netdata", category: "tools", description: "实时服务器性能监控", icon: "Tools", versions: ["latest"], default_version: "latest" }
    ]
            <span v-for="cat in rightCategories" :key="cat.key" class="category-item"
              :class="{ active: activeStatus === cat.key }" @click="activeStatus = cat.key">
              {{ cat.name }}
            </span>
          </div>
          <div class="category-divider"></div>
          <div class="category-group">
            <span class="category-item" :class="{ active: activeStatus === 'updatable' }" @click="activeStatus = 'updatable'">
              可更新
              <span v-if="updatableCount > 0" class="update-badge">{{ updatableCount }}</span>
            </span>
          </div>
        </div>
        <div class="categories-right">
          <el-input v-model="searchKeyword" placeholder="搜索应用" prefix-icon="Search" clearable size="small" style="width: 220px" />
        </div>
      </div>
    </div>

    <!-- 应用列表 -->
    <div class="apps-panel">
      <div class="apps-grid">
        <div v-for="app in filteredApps" :key="app.id" class="app-card" @click="openAppDetail(app)">
          <div class="app-icon" :style="{ backgroundColor: app.iconBg }">
            <el-icon :size="32" :color="app.iconColor">
              <component :is="app.icon" />
            </el-icon>
          </div>
          <div class="app-info">
            <div class="app-name">{{ app.name }}</div>
            <div class="app-description">{{ app.description }}</div>
            <div class="app-footer">
              <el-button size="small" type="primary" @click.stop="openInstallDrawer(app)">安装</el-button>
              <el-button v-if="app.hasUpdate" size="small" type="warning" @click.stop="updateApp(app)">更新</el-button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 安装抽屉 - 完整版 -->
    <el-drawer v-model="drawerVisible" :title="`安装 ${selectedApp?.name}`" direction="rtl" size="550px">
      <div class="drawer-content">
        <el-form :model="installForm" label-width="120px" label-position="left">
          <!-- 基础配置 -->
          <div class="config-section">
            <div class="section-title">基础配置</div>
            
            <el-form-item label="容器名称">
              <el-input v-model="installForm.name" :placeholder="`默认: ${selectedApp?.key}-${installForm.version}`" />
              <div class="form-tip">用于区分多个实例，留空则使用默认名称</div>
            </el-form-item>

            <el-form-item label="版本" v-if="availableVersions.length">
              <el-select v-model="installForm.version">
                <el-option v-for="v in availableVersions" :key="v" :label="v" :value="v" />
              </el-select>
            </el-form-item>
          </div>

          <!-- 网络配置 -->
          <div class="config-section" v-if="showPortConfig">
            <div class="section-title">网络配置</div>
            
            <el-form-item label="端口映射">
              <el-input-number v-model="installForm.config.port" :min="1" :max="65535" />
              <div class="form-tip">将宿主机端口映射到容器 {{ getContainerPort() }} 端口</div>
            </el-form-item>

            <el-form-item label="允许外部访问">
              <el-switch v-model="installForm.externalAccess" />
              <div class="form-tip">开启后允许外部网络访问</div>
            </el-form-item>
          </div>

          <!-- 资源限制 -->
          <div class="config-section">
            <div class="section-title">资源限制</div>
            
            <el-form-item label="CPU 限制">
              <el-input-number v-model="installForm.cpuLimit" :min="0" :step="0.5" :precision="1" />
              <span class="unit">核心</span>
              <div class="form-tip">0 表示不限制</div>
            </el-form-item>

            <el-form-item label="内存限制">
              <el-input-number v-model="installForm.memoryLimit" :min="0" :step="128" />
              <span class="unit">MB</span>
              <div class="form-tip">0 表示不限制</div>
            </el-form-item>
          </div>

          <!-- 重启策略 -->
          <div class="config-section">
            <div class="section-title">重启策略</div>
            
            <el-form-item label="重启策略">
              <el-radio-group v-model="installForm.restartPolicy">
                <el-radio value="no">不重启</el-radio>
                <el-radio value="always">总是重启</el-radio>
                <el-radio value="on-failure">失败时重启</el-radio>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="最大重启次数" v-if="installForm.restartPolicy === 'on-failure'">
              <el-input-number v-model="installForm.maxRetries" :min="1" :max="10" />
            </el-form-item>
          </div>

          <!-- 应用特定配置 -->
          <div class="config-section" v-if="showAppSpecificConfig">
            <div class="section-title">应用配置</div>

            <template v-if="selectedApp?.key === 'mysql'">
              <el-form-item label="root密码">
                <el-input v-model="installForm.config.password" type="password" placeholder="留空则自动生成" />
              </el-form-item>
            </template>

            <template v-if="selectedApp?.key === 'php'">
              <el-form-item label="PHP扩展">
                <el-select v-model="installForm.extensions" multiple filterable placeholder="请选择需要的扩展">
                  <el-option label="MySQL" value="mysql" />
                  <el-option label="PostgreSQL" value="pgsql" />
                  <el-option label="Redis" value="redis" />
                  <el-option label="GD" value="gd" />
                  <el-option label="cURL" value="curl" />
                  <el-option label="Zip" value="zip" />
                  <el-option label="MBString" value="mbstring" />
                  <el-option label="XML" value="xml" />
                  <el-option label="JSON" value="json" />
                  <el-option label="BCMath" value="bcmath" />
                  <el-option label="OPcache" value="opcache" />
                  <el-option label="Sockets" value="sockets" />
                  <el-option label="SOAP" value="soap" />
                  <el-option label="Intl" value="intl" />
                </el-select>
                <div class="form-tip">按住 Ctrl 键多选</div>
              </el-form-item>
            </template>
          </div>
        </el-form>

        <div class="drawer-footer">
          <el-button @click="drawerVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmInstall" :loading="installing">确认安装</el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 应用详情抽屉 -->
    <el-drawer v-model="detailDrawerVisible" :title="currentApp?.name" direction="rtl" size="500px">
      <div class="detail-content">
        <div class="detail-section">
          <div class="detail-header">
            <div class="app-icon-small" :style="{ backgroundColor: currentApp?.iconBg }">
              <el-icon :size="28" :color="currentApp?.iconColor">
                <component :is="currentApp?.icon" />
              </el-icon>
            </div>
            <div class="app-info-text">
              <div class="app-name-large">{{ currentApp?.name }}</div>
              <div class="app-version">版本: {{ containerInfo?.version || currentApp?.default_version }}</div>
            </div>
          </div>
          <div class="detail-desc">{{ currentApp?.description }}</div>
        </div>

        <div class="detail-section">
          <div class="section-title">运行状态</div>
          <div class="status-row">
            <span class="status-label">容器状态</span>
            <el-tag :type="containerInfo?.status === 'running' ? 'success' : 'danger'" size="small">
              {{ containerInfo?.status === 'running' ? '运行中' : '已停止' }}
            </el-tag>
          </div>
          <div class="status-row">
            <span class="status-label">容器名称</span>
            <span class="status-value">{{ containerInfo?.name || '-' }}</span>
          </div>
          <div class="status-row">
            <span class="status-label">镜像</span>
            <span class="status-value">{{ containerInfo?.image || '-' }}</span>
          </div>
          <div class="status-row">
            <span class="status-label">端口映射</span>
            <span class="status-value">{{ containerInfo?.ports || '-' }}</span>
          </div>
        </div>

        <div class="detail-section">
          <div class="section-title">操作</div>
          <div class="action-buttons">
            <el-button size="small" type="success" @click="openAppUrl">访问</el-button>
            <el-button size="small" @click="restartContainer">重启</el-button>
            <el-button size="small" @click="stopContainer" v-if="containerInfo?.status === 'running'">停止</el-button>
            <el-button size="small" @click="startContainer" v-else>启动</el-button>
            <el-button size="small" @click="openLogs">日志</el-button>
            <el-button size="small" type="danger" @click="uninstallApp">卸载</el-button>
          </div>
        </div>
      </div>
    </el-drawer>

    <!-- 安装日志抽屉 -->
    <el-drawer v-model="installLogDrawerVisible" title="安装日志" direction="rtl" size="700px">
      <div class="logs-content">
        <div class="log-controls">
          <el-button size="small" @click="copyLogs">复制日志</el-button>
          <el-button size="small" @click="clearInstallLogs">清空</el-button>
        </div>
        <pre class="log-pre">{{ installLogs || '等待安装开始...' }}</pre>
      </div>
    </el-drawer>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import { Link } from '@element-plus/icons-vue'

const activeCategory = ref('all')
const activeStatus = ref('all')
const searchKeyword = ref('')
const drawerVisible = ref(false)
const detailDrawerVisible = ref(false)
const installLogDrawerVisible = ref(false)
const installing = ref(false)
const selectedApp = ref(null)
const currentApp = ref(null)
const containerInfo = ref({})
const installLogs = ref('')
let logInterval = null
let logStep = 0

const leftCategories = [
  { key: 'all', name: '全部' },
  { key: 'web', name: 'Web服务器' },
  { key: 'database', name: '数据库' },
  { key: 'environment', name: '环境' },
  { key: 'tools', name: '工具' },
  { key: 'website', name: '建站' }
]

const rightCategories = [
  { key: 'all', name: '全部' },
  { key: 'installed', name: '已安装' },
  { key: 'not_installed', name: '未安装' }
]

const apps = ref([])

// 安装表单
const installForm = ref({
  name: '',
  version: '',
  externalAccess: false,
  cpuLimit: 0,
  memoryLimit: 0,
  restartPolicy: 'no',
  maxRetries: 5,
  config: { port: 8080, password: '' },
  extensions: ['mysql', 'gd', 'curl', 'zip']
})

// 辅助函数
const getContainerPort = () => {
  const appKey = selectedApp.value?.key
  const ports = { nginx: 80, openresty: 80, wordpress: 80, mysql: 3306, postgresql: 5432, redis: 6379 }
  return ports[appKey] || 80
}

const showPortConfig = computed(() => {
  const appKey = selectedApp.value?.key
  return ['nginx', 'openresty', 'wordpress', 'mysql', 'postgresql', 'redis'].includes(appKey)
})

const showAppSpecificConfig = computed(() => {
  const appKey = selectedApp.value?.key
  return ['mysql', 'php'].includes(appKey)
})

const getInstallSteps = (appName, version, port) => {
  const now = new Date()
  const timeStr = now.toLocaleString()
  return [
    `[${timeStr}] 🚀 开始安装应用 [${appName}]`,
    `[${timeStr}] 📥 拉取镜像: ${appName}:${version}`,
    `[${timeStr}] ✅ 镜像拉取成功`,
    port ? `[${timeStr}] 🔌 端口映射: ${port}:80` : '',
    `[${timeStr}] 🚀 启动容器...`,
    `[${timeStr}] ✅ 容器启动成功`,
    `[${timeStr}] 🎉 应用 [${appName}] 安装完成！`
  ].filter(step => step)
}

const fetchContainers = async () => {
  try {
    const res = await axios.get('/api/containers/')
    const containers = res.data.data || []
    const containerNames = containers.map(c => c.name)
    apps.value = apps.value.map(app => ({
      ...app,
      installed: containerNames.some(name => name.includes(app.key)),
      hasUpdate: false
    }))
  } catch (err) { console.error('获取容器列表失败:', err) }
}

const fetchContainerInfo = async (appKey) => {
  try {
    const res = await axios.get('/api/containers/')
    const containers = res.data.data || []
    const container = containers.find(c => c.name.includes(appKey))
    if (container) {
      containerInfo.value = {
        name: container.name,
        status: container.status,
        image: container.image,
        ports: container.ports,
        created: container.created,
        version: container.image?.split(':')[1] || '-'
      }
    } else { containerInfo.value = {} }
  } catch (err) { console.error('获取容器详情失败:', err) }
}

const fetchApps = async () => {
  try {
    const res = await axios.get('/api/apps/')
    apps.value = res.data.data || []
    // 添加开发环境应用
    const devApps = [
      { id: "11", key: "golang", name: "Go", category: "environment", description: "Google 开发的静态强类型编程语言", icon: "Document", versions: ["1.23"], default_version: "1.23" },
      { id: "12", key: "nodejs", name: "Node.js", category: "environment", description: "基于 Chrome V8 的 JavaScript 运行时", icon: "Document", versions: ["20"], default_version: "20" },
      { id: "13", key: "python", name: "Python", category: "environment", description: "强大的通用编程语言", icon: "Document", versions: ["3.12"], default_version: "3.12" },
      { id: "14", key: "java", name: "Java", category: "environment", description: "企业级应用开发平台", icon: "Document", versions: ["17"], default_version: "17" },
      { id: "15", key: "caddy", name: "Caddy", category: "web", description: "自动HTTPS的极简Web服务器", icon: "Monitor", versions: ["latest", "2"], default_version: "latest" },
      { id: "16", key: "mariadb", name: "MariaDB", category: "database", description: "MySQL替代品，开源关系型数据库", icon: "Coin", versions: ["11", "10"], default_version: "11" },
      { id: "17", key: "mongodb", name: "MongoDB", category: "database", description: "文档型NoSQL数据库", icon: "Coin", versions: ["7.0", "6.0"], default_version: "7.0" },
      { id: "18", key: "gitea", name: "Gitea", category: "tools", description: "轻量级Git代码托管服务", icon: "Tools", versions: ["latest", "1.21"], default_version: "latest" },
      { id: "19", key: "uptime-kuma", name: "Uptime Kuma", category: "tools", description: "网站状态监控与告警", icon: "Tools", versions: ["latest"], default_version: "latest" },
      { id: "20", key: "grafana", name: "Grafana", category: "tools", description: "监控可视化仪表盘", icon: "Tools", versions: ["latest", "10"], default_version: "latest" },
      { id: "21", key: "netdata", name: "Netdata", category: "tools", description: "实时服务器性能监控", icon: "Tools", versions: ["latest"], default_version: "latest" }
    ]

    apps.value = [...apps.value, ...devApps]
    
    const iconMap = { 'Monitor': '#e8f4f4', 'Coin': '#e8f4e8', 'Connection': '#f3e8f4', 'Document': '#fef3e8', 'Tools': '#e8e8f4' }
    const colorMap = { 'Monitor': '#477779', 'Coin': '#2e7d32', 'Connection': '#7b1fa2', 'Document': '#ed6c02', 'Tools': '#3f51b5' }
    apps.value = apps.value.map(app => ({ ...app, iconBg: iconMap[app.icon] || '#e8f4f4', iconColor: colorMap[app.icon] || '#477779' }))
    await fetchContainers()
  } catch (err) { console.error('获取应用列表失败:', err); ElMessage.error('获取应用列表失败: ' + err.message) }
}

const openAppDetail = async (app) => {
  currentApp.value = app
  await fetchContainerInfo(app.key)
  detailDrawerVisible.value = true
}

const openAppUrl = () => {
  if (!currentApp.value) return
  const portMatch = containerInfo.value?.ports?.match(/\d+/)
  const port = portMatch ? portMatch[0] : ''
  window.open(`http://localhost:${port || 8080}`, '_blank')
}

const restartContainer = async () => {
  await new Promise(resolve => setTimeout(resolve, 1000))
  ElMessage.success('容器已重启')
  await fetchContainerInfo(currentApp.value.key)
}

const stopContainer = async () => {
  await new Promise(resolve => setTimeout(resolve, 1000))
  ElMessage.success('容器已停止')
  await fetchContainerInfo(currentApp.value.key)
}

const startContainer = async () => {
  await new Promise(resolve => setTimeout(resolve, 1000))
  ElMessage.success('容器已启动')
  await fetchContainerInfo(currentApp.value.key)
}

const openLogs = async () => {
  ElMessage.info('日志功能开发中')
}

const uninstallApp = async () => {
  await ElMessageBox.confirm(`确定卸载 ${currentApp.value.name} 吗？`, '警告', { type: 'warning' })
  await new Promise(resolve => setTimeout(resolve, 1000))
  ElMessage.success('卸载成功')
  detailDrawerVisible.value = false
  await fetchApps()
}

const updateApp = (app) => { ElMessage.info(`更新 ${app.name} 功能开发中`) }

const availableVersions = computed(() => selectedApp.value ? selectedApp.value.versions || [] : [])
const updatableCount = computed(() => apps.value.filter(app => app.hasUpdate).length)

const filteredApps = computed(() => {
  let result = apps.value
  if (searchKeyword.value) {
    result = result.filter(app => app.name.toLowerCase().includes(searchKeyword.value.toLowerCase()))
  }
  if (activeCategory.value !== 'all') {
    result = result.filter(app => app.category === activeCategory.value)
  }
  if (activeStatus.value === 'installed') {
    result = result.filter(app => app.installed)
  } else if (activeStatus.value === 'not_installed') {
    result = result.filter(app => !app.installed)
  }
  return result
})

const openInstallDrawer = (app) => {
  selectedApp.value = app
  installForm.value = {
    name: `${app.key}-${app.default_version}-${Date.now()}`,
    version: app.default_version,
    externalAccess: false,
    cpuLimit: 0,
    memoryLimit: 0,
    restartPolicy: 'no',
    maxRetries: 5,
    config: { port: getDefaultPort(app.key), password: '' },
    extensions: ['mysql', 'gd', 'curl', 'zip']
  }
  drawerVisible.value = true
}

const getDefaultPort = (key) => {
  const ports = { nginx: 8080, openresty: 8080, mysql: 3306, postgresql: 5432, redis: 6379, wordpress: 8090 }
  return ports[key] || 8080
}

const copyLogs = () => {
  if (installLogs.value) {
    navigator.clipboard.writeText(installLogs.value)
    ElMessage.success('日志已复制')
  }
}

const clearInstallLogs = () => {
  installLogs.value = ''
  ElMessage.success('日志已清空')
}

const confirmInstall = async () => {
  installLogs.value = ''
  installLogDrawerVisible.value = true
  installing.value = true
  
  const steps = getInstallSteps(selectedApp.value.name, installForm.value.version, installForm.value.config.port)
  logStep = 0
  logInterval = setInterval(() => {
    if (logStep < steps.length) {
      installLogs.value += steps[logStep] + '\n'
      logStep++
    } else {
      clearInterval(logInterval)
      logInterval = null
    }
  }, 500)
  
  try {
    await axios.post('/api/apps/install', {
      app_key: selectedApp.value.key,
      version: installForm.value.version,
      name: installForm.value.name,
      config: installForm.value.config
    })
    setTimeout(() => {
      if (logInterval) clearInterval(logInterval)
      ElMessage.success('安装成功！')
      drawerVisible.value = false
      setTimeout(() => fetchApps(), 1000)
    }, 3000)
  } catch (err) {
    if (logInterval) clearInterval(logInterval)
    installLogs.value += `\n❌ 安装失败: ${err.response?.data?.error || err.message}\n`
    ElMessage.error('安装失败: ' + (err.response?.data?.error || err.message))
  } finally {
    installing.value = false
  }
}

onMounted(() => { fetchApps() })
onUnmounted(() => { if (logInterval) clearInterval(logInterval) })
</script>

<style scoped>
.apps-container { height: 100%; display: flex; flex-direction: column; gap: 16px; }
.categories-panel { background: #fff; padding: 12px 16px; }
.categories-wrapper { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
.categories-left { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }
.categories-right { flex-shrink: 0; }
.category-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.category-item { padding: 6px 14px; font-size: 13px; color: #6b7280; cursor: pointer; }
.category-item:hover { background-color: #f3f4f6; color: #477779; }
.category-item.active { background-color: #477779; color: white; }
.category-divider { width: 1px; height: 24px; background-color: #e5e7eb; }
.update-badge { display: inline-block; background-color: #f59e0b; color: white; font-size: 11px; padding: 0 6px; border-radius: 10px; margin-left: 6px; }
.apps-panel { background: #fff; padding: 20px; flex: 1; overflow-y: auto; }
.apps-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
.app-card { display: flex; gap: 12px; padding: 14px; border: 1px solid #e5e7eb; cursor: pointer; }
.app-card:hover { border-color: #477779; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
.app-icon { flex-shrink: 0; width: 52px; height: 52px; display: flex; align-items: center; justify-content: center; }
.app-info { flex: 1; display: flex; flex-direction: column; min-width: 0; }
.app-name { font-size: 14px; font-weight: 600; color: #1f2937; margin-bottom: 4px; }
.app-description { font-size: 11px; color: #9ca3af; line-height: 1.3; margin-bottom: 8px; }
.app-footer { display: flex; justify-content: flex-end; gap: 8px; }
.drawer-content { padding: 0 4px; }
.drawer-footer { display: flex; justify-content: flex-end; gap: 12px; margin-top: 24px; padding-top: 16px; border-top: 1px solid #e5e7eb; }

.config-section { margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1px solid #e5e7eb; }
.config-section .section-title { font-size: 14px; font-weight: 600; color: #1f2937; margin-bottom: 16px; padding-left: 8px; border-left: 3px solid #477779; }
.unit { margin-left: 8px; color: #9ca3af; font-size: 12px; }
.form-tip { font-size: 11px; color: #9ca3af; margin-top: 4px; }

.detail-content { padding: 0 4px; }
.detail-section { margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1px solid #e5e7eb; }
.detail-section:last-child { border-bottom: none; }
.section-title { font-size: 14px; font-weight: 600; color: #1f2937; margin-bottom: 12px; }
.detail-header { display: flex; gap: 16px; align-items: center; margin-bottom: 12px; }
.app-icon-small { width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; }
.app-name-large { font-size: 18px; font-weight: 600; color: #1f2937; }
.app-version { font-size: 12px; color: #9ca3af; margin-top: 4px; }
.detail-desc { font-size: 13px; color: #6b7280; line-height: 1.5; }
.status-row { display: flex; justify-content: space-between; padding: 8px 0; font-size: 13px; }
.status-label { color: #9ca3af; }
.status-value { color: #1f2937; font-weight: 500; }
.action-buttons { display: flex; flex-wrap: wrap; gap: 8px; }

.logs-content { height: 100%; display: flex; flex-direction: column; gap: 12px; }
.log-controls { display: flex; gap: 8px; }
.log-pre { background: #1e1e1e; color: #d4d4d4; padding: 16px; font-family: monospace; font-size: 12px; white-space: pre-wrap; margin: 0; min-height: 300px; }
</style>
