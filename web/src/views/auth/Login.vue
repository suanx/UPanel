<template>
  <div class="login-container">
    <!-- 左侧介绍区域 -->
    <div class="login-left">
      <div class="logo-area">
        <div class="logo-icon">
          <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect width="48" height="48" rx="12" fill="white" fill-opacity="0.2"/>
            <path d="M24 14L30 20L24 26L18 20L24 14Z" fill="white"/>
            <path d="M24 22L30 28L24 34L18 28L24 22Z" fill="white" fill-opacity="0.7"/>
          </svg>
        </div>
        <h1 class="logo-title">UPanel</h1>
        <p class="logo-subtitle">轻量级 Linux 服务器面板</p>
      </div>
      
      <div class="features">
        <div class="feature-item">
          <div class="feature-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
              <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
          </div>
          <span>容器化管理，一键部署</span>
        </div>
        <div class="feature-item">
          <div class="feature-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
              <rect x="3" y="3" width="18" height="18" rx="2"/>
              <path d="M3 9h18"/>
            </svg>
          </div>
          <span>可视化管理网站、数据库</span>
        </div>
        <div class="feature-item">
          <div class="feature-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <path d="M12 6v6l4 2"/>
            </svg>
          </div>
          <span>计划任务、备份还原</span>
        </div>
        <div class="feature-item">
          <div class="feature-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
              <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
            </svg>
          </div>
          <span>安全防护，防火墙管理</span>
        </div>
      </div>
      
      <div class="footer-note">
        <p>开源 · 免费 · 高效</p>
      </div>
    </div>

    <!-- 右侧登录区域 -->
    <div class="login-right">
      <div class="login-card">
        <div class="card-header">
          <h2>欢迎回来</h2>
          <p>请登录您的账号</p>
        </div>
        
        <el-form :model="form" :rules="rules" ref="formRef" class="login-form">
          <el-form-item prop="username">
            <el-input v-model="form.username" placeholder="用户名" size="large" prefix-icon="User" />
          </el-form-item>
          <el-form-item prop="password">
            <el-input v-model="form.password" type="password" placeholder="密码" size="large" prefix-icon="Lock" show-password @keyup.enter="handleLogin" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" size="large" class="login-btn" :loading="loading" @click="handleLogin">登录</el-button>
          </el-form-item>
        </el-form>
        
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { ElMessage } from 'element-plus'

const router = useRouter()
const formRef = ref()
const loading = ref(false)

const form = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

const handleLogin = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    loading.value = true
    try {
      const res = await axios.post('/api/auth/login', form)
      localStorage.setItem('token', res.data.token)
      localStorage.setItem('loginTime', Date.now().toString())
      ElMessage.success('登录成功')
      router.push('/')
    } catch (err) {
      ElMessage.error(err.response?.data?.error || '登录失败')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style scoped>
.login-container {
  display: flex;
  width: 100%;
  min-height: 100vh;
  background: linear-gradient(135deg, #477779 0%, #2d5a5c 50%, #1a3d3f 100%);
}

.login-left {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 60px;
  color: white;
}

.logo-area {
  margin-bottom: 60px;
}

.logo-icon {
  margin-bottom: 20px;
}

.logo-title {
  font-size: 42px;
  font-weight: 700;
  margin: 0 0 8px 0;
  letter-spacing: 2px;
}

.logo-subtitle {
  font-size: 16px;
  opacity: 0.85;
  margin: 0;
}

.features {
  display: flex;
  flex-direction: column;
  gap: 24px;
  margin-bottom: 60px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  opacity: 0.9;
}

.feature-icon {
  width: 32px;
  height: 32px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.footer-note {
  margin-top: auto;
  font-size: 13px;
  opacity: 0.7;
}

.login-right {
  width: 420px;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 32px;
}

.login-card {
  width: 100%;
  max-width: 360px;
}

.card-header {
  text-align: center;
  margin-bottom: 28px;
}

.card-header h2 {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 6px 0;
}

.card-header p {
  font-size: 13px;
  color: #9ca3af;
  margin: 0;
}

.login-form {
  margin-bottom: 20px;
}

.login-form :deep(.el-input__wrapper) {
  border-radius: 8px;
  padding: 2px 12px;
  box-shadow: 0 0 0 1px #e5e7eb inset;
}

.login-form :deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px #477779 inset;
}

.login-form :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px #477779 inset;
}

.login-btn {
  width: 100%;
  background: #477779;
  border: none;
  border-radius: 8px;
  padding: 10px;
  font-size: 15px;
  font-weight: 500;
}

.login-btn:hover {
  background: #2d5a5c;
}

</style>
