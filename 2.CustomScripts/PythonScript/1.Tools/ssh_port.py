import sys
import re
import subprocess
import threading
import os
import platform
import socket
from datetime import datetime
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QGroupBox,
    QRadioButton, QLineEdit, QLabel, QPushButton, QTextEdit, QComboBox,
    QSplitter, QStatusBar, QStyleFactory, QFileDialog, QCheckBox, QGridLayout,
    QFrame, QSizePolicy
)
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont, QPalette, QColor, QIcon, QFontDatabase

class SSHManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("SSH Tunnel Manager v1.5")
        self.setGeometry(100, 100, 1000, 720)
        self.processes = {}
        self.dark_mode = False
        self.last_operation_time = "No operation yet"
        self.remote_info = {}
        self.openssl_version = self.get_openssl_version()
        self.current_language = "en"  # Default language: English
        self.init_ui()
        self.load_config()
        
    def init_ui(self):
        # 创建主窗口部件
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setSpacing(10)
        
        # 创建分割器（左侧控制面板 + 右侧日志）
        splitter = QSplitter(Qt.Horizontal)
        
        # 左侧控制面板
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_layout.setSpacing(15)
        
        # 模式选择
        self.mode_group = QGroupBox()
        mode_layout = QVBoxLayout()
        self.local_forward_radio = QRadioButton()
        self.remote_forward_radio = QRadioButton()
        self.local_forward_radio.setChecked(True)
        mode_layout.addWidget(self.local_forward_radio)
        mode_layout.addWidget(self.remote_forward_radio)
        self.mode_group.setLayout(mode_layout)
        
        # 连接设置
        self.settings_group = QGroupBox()
        settings_layout = QGridLayout()
        settings_layout.setColumnStretch(1, 3)
        
        # 服务器设置
        self.server_label = QLabel()
        settings_layout.addWidget(self.server_label, 0, 0)
        self.server_input = QLineEdit()
        self.server_input.setPlaceholderText("user@hostname or IP address")
        settings_layout.addWidget(self.server_input, 0, 1, 1, 2)
        
        # 端口设置
        self.port_label = QLabel()
        settings_layout.addWidget(self.port_label, 1, 0)
        self.port_input = QLineEdit()
        self.port_input.setPlaceholderText("Format: local_port:remote_port (multiple separated by commas)")
        settings_layout.addWidget(self.port_input, 1, 1, 1, 2)
        
        # 示例标签
        self.example_label = QLabel()
        self.example_label.setStyleSheet("color: gray; font-size: 10px;")
        settings_layout.addWidget(self.example_label, 2, 1, 1, 2)
        
        # 认证方式
        self.auth_label = QLabel()
        settings_layout.addWidget(self.auth_label, 3, 0)
        self.auth_method = QComboBox()
        self.auth_method.currentIndexChanged.connect(self.toggle_auth_fields)
        settings_layout.addWidget(self.auth_method, 3, 1)
        
        # 证书路径选择
        self.cert_path_label = QLabel()
        self.cert_path_input = QLineEdit()
        self.cert_path_input.setPlaceholderText("Select private key file")
        self.cert_browse_button = QPushButton()
        self.cert_browse_button.clicked.connect(self.browse_cert_file)
        settings_layout.addWidget(self.cert_path_label, 4, 0)
        settings_layout.addWidget(self.cert_path_input, 4, 1)
        settings_layout.addWidget(self.cert_browse_button, 4, 2)
        
        # 用户名和密码字段
        self.username_label = QLabel()
        self.username_input = QLineEdit()
        self.username_input.setPlaceholderText("SSH username")
        self.password_label = QLabel()
        self.password_input = QLineEdit()
        self.password_input.setPlaceholderText("SSH password")
        self.password_input.setEchoMode(QLineEdit.Password)
        self.show_password_check = QCheckBox()
        self.show_password_check.stateChanged.connect(self.toggle_password_visibility)
        
        settings_layout.addWidget(self.username_label, 5, 0)
        settings_layout.addWidget(self.username_input, 5, 1, 1, 2)
        settings_layout.addWidget(self.password_label, 6, 0)
        settings_layout.addWidget(self.password_input, 6, 1)
        settings_layout.addWidget(self.show_password_check, 6, 2)
        
        # SSH选项
        self.ssh_group = QGroupBox()
        ssh_layout = QHBoxLayout()
        self.verbose_check = QCheckBox()
        self.compression_check = QCheckBox()
        self.no_command_check = QCheckBox()
        ssh_layout.addWidget(self.verbose_check)
        ssh_layout.addWidget(self.compression_check)
        ssh_layout.addWidget(self.no_command_check)
        self.ssh_group.setLayout(ssh_layout)
        settings_layout.addWidget(self.ssh_group, 7, 0, 1, 3)
        
        # 按钮区域
        button_layout = QHBoxLayout()
        self.connect_button = QPushButton()
        self.connect_button.setIcon(QIcon.fromTheme("network-connect"))
        self.connect_button.clicked.connect(self.toggle_connection)
        self.connect_button.setStyleSheet("background-color: #4CAF50; color: white; padding: 8px;")
        
        self.clear_button = QPushButton()
        self.clear_button.setIcon(QIcon.fromTheme("edit-clear"))
        self.clear_button.clicked.connect(self.clear_fields)
        self.clear_button.setStyleSheet("background-color: #f44336; color: white; padding: 8px;")
        
        button_layout.addWidget(self.connect_button)
        button_layout.addWidget(self.clear_button)
        
        self.settings_group.setLayout(settings_layout)
        
        # 将按钮布局添加到设置组下方
        settings_layout.addLayout(button_layout, 8, 0, 1, 3)
        
        # 活动隧道
        self.tunnels_group = QGroupBox()
        tunnels_layout = QVBoxLayout()
        self.tunnels_list = QTextEdit()
        self.tunnels_list.setReadOnly(True)
        self.tunnels_list.setMinimumHeight(100)
        tunnels_layout.addWidget(self.tunnels_list)
        self.tunnels_group.setLayout(tunnels_layout)
        
        # 添加到左侧面板
        left_layout.addWidget(self.mode_group)
        left_layout.addWidget(self.settings_group)
        left_layout.addWidget(self.tunnels_group)
        
        # 右侧面板
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setSpacing(15)
        
        # 日志信息
        self.log_group = QGroupBox()
        log_layout = QVBoxLayout()
        self.log_output = QTextEdit()
        self.log_output.setReadOnly(True)
        self.log_output.setFont(QFont("Consolas", 10))
        log_layout.addWidget(self.log_output)
        self.log_group.setLayout(log_layout)
        
        # 系统状态
        self.status_group = QGroupBox()
        status_layout = QVBoxLayout()
        self.status_output = QTextEdit()
        self.status_output.setReadOnly(True)
        self.status_output.setMinimumHeight(200)
        self.status_output.setMaximumHeight(270)
        self.status_output.setFont(QFont("Arial", 9))
        status_layout.addWidget(self.status_output)
        self.status_group.setLayout(status_layout)
        
        # 添加到右侧面板
        right_layout.addWidget(self.log_group, 3)
        right_layout.addWidget(self.status_group, 1)
        
        # 添加到分割器
        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setSizes([400, 600])
        
        main_layout.addWidget(splitter)
        
        # 创建状态栏
        status_bar = QStatusBar()
        self.setStatusBar(status_bar)
        
        # 作者和版本信息
        author_frame = QFrame()
        author_layout = QVBoxLayout(author_frame)
        author_layout.setContentsMargins(5, 0, 0, 0)
        
        mono_font = QFont("Monospace", 10)
        mono_font.setBold(True)
        
        self.author_label = QLabel()
        self.author_label.setFont(mono_font)
        self.author_label.setStyleSheet("color: gray;")
        
        self.version_label = QLabel()
        self.version_label.setFont(mono_font)
        self.version_label.setStyleSheet("color: gray;")
        
        author_layout.addWidget(self.author_label)
        author_layout.addWidget(self.version_label)
        
        status_bar.addWidget(author_frame)
        
        spacer = QWidget()
        spacer.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        status_bar.addWidget(spacer)
        
        # 语言选择器
        self.language_label = QLabel("Language:")
        self.language_combo = QComboBox()
        self.language_combo.addItem("English", "en")
        self.language_combo.addItem("中文", "zh")
        self.language_combo.addItem("日本語", "ja")
        self.language_combo.currentIndexChanged.connect(self.change_language)
        
        language_layout = QHBoxLayout()
        language_layout.addWidget(self.language_label)
        language_layout.addWidget(self.language_combo)
        language_widget = QWidget()
        language_widget.setLayout(language_layout)
        status_bar.addPermanentWidget(language_widget)
        
        # 主题切换按钮
        self.theme_button = QPushButton()
        self.theme_button.setIcon(QIcon.fromTheme("color-management"))
        self.theme_button.clicked.connect(self.toggle_theme)
        status_bar.addPermanentWidget(self.theme_button)
        
        # 初始认证字段状态
        self.toggle_auth_fields()
        
        # 设置初始语言和主题
        self.change_language(0)
        self.apply_theme()
        
        # 启动定时器更新状态
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_status)
        self.timer.start(1000)
        
        # 记录初始状态
        self.log_message("SSH Tunnel Manager started")
        self.update_status()
    
    def change_language(self, index):
        self.current_language = self.language_combo.currentData()
        self.translate_ui()
    
    def translate_ui(self):
        translations = {
            "en": {
                "window_title": "SSH Tunnel Manager v1.5",
                "mode_group": "Connection Mode",
                "local_forward": "Local Port Forwarding (from remote to local)",
                "remote_forward": "Remote Port Forwarding (from local to remote)",
                "settings_group": "Connection Settings",
                "server_label": "Server Address:",
                "port_label": "Port Mapping:",
                "example_label": "Example: 8080:8080, 9000:3000, 5432:5432",
                "auth_label": "Authentication:",
                "auth_methods": ["Certificate", "Username/Password"],
                "cert_path_label": "Certificate Path:",
                "cert_browse": "Browse...",
                "username_label": "Username:",
                "password_label": "Password:",
                "show_password": "Show Password",
                "ssh_group": "SSH Options",
                "verbose": "-v (verbose output)",
                "compression": "-C (compression)",
                "no_command": "-N (no remote command)",
                "connect_button": "Connect",
                "disconnect_button": "Disconnect",
                "clear_button": "Clear",
                "tunnels_group": "Active Tunnels",
                "no_tunnels": "No active tunnels",
                "log_group": "Log Information",
                "status_group": "System Status",
                "active_tunnels": "Active Tunnels:",
                "last_operation": "Last Operation:",
                "mode": "Mode:",
                "auth": "Authentication:",
                "local_openssl": "Local OpenSSL:",
                "remote_info": "Remote Host Info:",
                "ip_address": "IP Address:",
                "hostname": "Hostname:",
                "os": "Operating System:",
                "remote_openssl": "Remote OpenSSL:",
                "theme_button": "Toggle Dark Mode",
                "author": "Author: Phony",
                "version": "Version: 1.5",
                "clear_message": "Fields cleared"
            },
            "zh": {
                "window_title": "SSH隧道管理工具 v1.5",
                "mode_group": "连接模式",
                "local_forward": "本地端口转发 (从远程主机连接到本地)",
                "remote_forward": "远程端口转发 (从本地连接到远程主机)",
                "settings_group": "连接设置",
                "server_label": "服务器地址:",
                "port_label": "端口映射:",
                "example_label": "示例: 8080:8080, 9000:3000, 5432:5432",
                "auth_label": "认证方式:",
                "auth_methods": ["证书验证", "用户名密码验证"],
                "cert_path_label": "证书路径:",
                "cert_browse": "浏览...",
                "username_label": "用户名:",
                "password_label": "密码:",
                "show_password": "显示密码",
                "ssh_group": "SSH选项",
                "verbose": "-v (详细输出)",
                "compression": "-C (压缩)",
                "no_command": "-N (不执行远程命令)",
                "connect_button": "建立连接",
                "disconnect_button": "断开连接",
                "clear_button": "清空",
                "tunnels_group": "活动隧道",
                "no_tunnels": "没有活动隧道",
                "log_group": "日志信息",
                "status_group": "系统状态",
                "active_tunnels": "活动隧道数量:",
                "last_operation": "最后操作:",
                "mode": "模式:",
                "auth": "认证方式:",
                "local_openssl": "本地OpenSSL:",
                "remote_info": "远程主机信息:",
                "ip_address": "IP地址:",
                "hostname": "主机名:",
                "os": "操作系统:",
                "remote_openssl": "远程OpenSSL:",
                "theme_button": "切换夜间模式",
                "author": "作者: Phony",
                "version": "版本: 1.5",
                "clear_message": "输入字段已清空"
            },
            "ja": {
                "window_title": "SSHトンネル管理ツール v1.5",
                "mode_group": "接続モード",
                "local_forward": "ローカルポート転送 (リモートからローカルへ)",
                "remote_forward": "リモートポート転送 (ローカルからリモートへ)",
                "settings_group": "接続設定",
                "server_label": "サーバーアドレス:",
                "port_label": "ポートマッピング:",
                "example_label": "例: 8080:8080, 9000:3000, 5432:5432",
                "auth_label": "認証方法:",
                "auth_methods": ["証明書認証", "ユーザー名/パスワード認証"],
                "cert_path_label": "証明書パス:",
                "cert_browse": "参照...",
                "username_label": "ユーザー名:",
                "password_label": "パスワード:",
                "show_password": "パスワードを表示",
                "ssh_group": "SSHオプション",
                "verbose": "-v (詳細出力)",
                "compression": "-C (圧縮)",
                "no_command": "-N (リモートコマンドを実行しない)",
                "connect_button": "接続",
                "disconnect_button": "切断",
                "clear_button": "クリア",
                "tunnels_group": "アクティブなトンネル",
                "no_tunnels": "アクティブなトンネルはありません",
                "log_group": "ログ情報",
                "status_group": "システム状態",
                "active_tunnels": "アクティブなトンネル:",
                "last_operation": "最後の操作:",
                "mode": "モード:",
                "auth": "認証方法:",
                "local_openssl": "ローカルOpenSSL:",
                "remote_info": "リモートホスト情報:",
                "ip_address": "IPアドレス:",
                "hostname": "ホスト名:",
                "os": "オペレーティングシステム:",
                "remote_openssl": "リモートOpenSSL:",
                "theme_button": "ダークモード切替",
                "author": "作者: Phony",
                "version": "バージョン: 1.5",
                "clear_message": "フィールドをクリアしました"
            }
        }
        
        lang = translations[self.current_language]
        
        # 设置窗口标题
        self.setWindowTitle(lang["window_title"])
        
        # 设置控件文本
        self.mode_group.setTitle(lang["mode_group"])
        self.local_forward_radio.setText(lang["local_forward"])
        self.remote_forward_radio.setText(lang["remote_forward"])
        
        self.settings_group.setTitle(lang["settings_group"])
        self.server_label.setText(lang["server_label"])
        self.port_label.setText(lang["port_label"])
        self.example_label.setText(lang["example_label"])
        self.auth_label.setText(lang["auth_label"])
        
        # 更新认证方法下拉框
        self.auth_method.clear()
        self.auth_method.addItems(lang["auth_methods"])
        
        self.cert_path_label.setText(lang["cert_path_label"])
        self.cert_browse_button.setText(lang["cert_browse"])
        self.username_label.setText(lang["username_label"])
        self.password_label.setText(lang["password_label"])
        self.show_password_check.setText(lang["show_password"])
        
        self.ssh_group.setTitle(lang["ssh_group"])
        self.verbose_check.setText(lang["verbose"])
        self.compression_check.setText(lang["compression"])
        self.no_command_check.setText(lang["no_command"])
        
        # 根据当前状态设置连接按钮文本
        if self.connect_button.text() == "Disconnect" or self.connect_button.text() == "断开连接" or self.connect_button.text() == "切断":
            self.connect_button.setText(lang["disconnect_button"])
        else:
            self.connect_button.setText(lang["connect_button"])
        
        self.clear_button.setText(lang["clear_button"])
        
        self.tunnels_group.setTitle(lang["tunnels_group"])
        # 更新活动隧道列表
        if self.tunnels_list.toPlainText() == "No active tunnels" or \
           self.tunnels_list.toPlainText() == "没有活动隧道" or \
           self.tunnels_list.toPlainText() == "アクティブなトンネルはありません":
            self.tunnels_list.setPlainText(lang["no_tunnels"])
        
        self.log_group.setTitle(lang["log_group"])
        self.status_group.setTitle(lang["status_group"])
        
        # 更新状态栏文本
        self.author_label.setText(lang["author"])
        self.version_label.setText(lang["version"])
        self.theme_button.setText(lang["theme_button"])
    
    def get_openssl_version(self):
        try:
            result = subprocess.run(
                ['openssl', 'version'],
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except:
            return "OpenSSL version unknown"
    
    def get_remote_info(self, server):
        try:
            host = server.split('@')[-1] if '@' in server else server
            
            ip_address = socket.gethostbyname(host)
            
            os_info = "Unknown OS"
            try:
                ssh_cmd = f"ssh {server} 'uname -a'"
                result = subprocess.run(
                    ssh_cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                if result.returncode == 0:
                    os_info = result.stdout.strip()
                else:
                    os_info = f"Linux (unknown version)"
            except:
                try:
                    ssh_cmd = f"ssh {server} 'lsb_release -d'"
                    result = subprocess.run(
                        ssh_cmd,
                        shell=True,
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if result.returncode == 0:
                        os_info = result.stdout.strip().split(':')[-1].strip()
                except:
                    pass
                
            remote_openssl = "Unknown"
            try:
                ssh_cmd = f"ssh {server} 'openssl version'"
                result = subprocess.run(
                    ssh_cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                if result.returncode == 0:
                    remote_openssl = result.stdout.strip()
            except:
                pass
            
            return {
                'ip': ip_address,
                'host': host,
                'os': os_info,
                'openssl': remote_openssl
            }
        except Exception as e:
            return {
                'ip': "Failed to get",
                'host': server,
                'os': f"Failed to get system info: {str(e)}",
                'openssl': "Failed to get"
            }
    
    def toggle_auth_fields(self):
        is_cert_auth = self.auth_method.currentText() == "Certificate" or \
                        self.auth_method.currentText() == "证书验证" or \
                        self.auth_method.currentText() == "証明書認証"
        
        self.cert_path_label.setVisible(is_cert_auth)
        self.cert_path_input.setVisible(is_cert_auth)
        self.cert_browse_button.setVisible(is_cert_auth)
        
        self.username_label.setVisible(not is_cert_auth)
        self.username_input.setVisible(not is_cert_auth)
        self.password_label.setVisible(not is_cert_auth)
        self.password_input.setVisible(not is_cert_auth)
        self.show_password_check.setVisible(not is_cert_auth)
    
    def toggle_password_visibility(self, state):
        if state == Qt.Checked:
            self.password_input.setEchoMode(QLineEdit.Normal)
        else:
            self.password_input.setEchoMode(QLineEdit.Password)
    
    def browse_cert_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Select SSH Private Key", 
            os.path.expanduser("~/.ssh"), 
            "Private Key Files (*.pem *.key);;All Files (*)"
        )
        if file_path:
            self.cert_path_input.setText(file_path)
            self.log_message(f"Selected certificate: {file_path}")
    
    def load_config(self):
        self.server_input.setText("user@example.com")
        self.port_input.setText("8080:8080, 1234:1234")
        
        default_cert_paths = [
            os.path.expanduser("~/.ssh/id_rsa"),
            os.path.expanduser("~/.ssh/id_ed25519")
        ]
        
        for path in default_cert_paths:
            if os.path.exists(path):
                self.cert_path_input.setText(path)
                break
    
    def toggle_theme(self):
        self.dark_mode = not self.dark_mode
        self.apply_theme()
        self.log_message(f"Switched to {'dark' if self.dark_mode else 'light'} mode")
    
    def apply_theme(self):
        if self.dark_mode:
            dark_style = """
                QWidget {
                    background-color: #2d2d2d;
                    color: #e0e0e0;
                    border: none;
                }
                
                QMainWindow {
                    background-color: #252525;
                }
                
                QGroupBox {
                    background-color: #333;
                    color: #e0e0e0;
                    border: 1px solid #444;
                    border-radius: 5px;
                    margin-top: 1ex;
                    padding-top: 10px;
                    font-weight: bold;
                }
                
                QGroupBox::title {
                    subcontrol-origin: margin;
                    subcontrol-position: top center;
                    padding: 0 5px;
                    background-color: #333;
                    color: #e0e0e0;
                }
                
                QTextEdit, QLineEdit, QComboBox, QCheckBox {
                    background-color: #3a3a3a;
                    color: #f0f0f0;
                    border: 1px solid #555;
                    padding: 5px;
                    border-radius: 3px;
                }
                
                QPushButton {
                    background-color: #4a4a4a;
                    color: white;
                    border: 1px solid #555;
                    padding: 8px;
                    border-radius: 4px;
                }
                
                QPushButton:hover {
                    background-color: #5a5a5a;
                }
                
                QPushButton:pressed {
                    background-color: #3a3a3a;
                }
                
                QPushButton:disabled {
                    background-color: #333;
                    color: #777;
                }
                
                QRadioButton, QLabel {
                    color: #e0e0e0;
                }
                
                QSplitter::handle {
                    background-color: #444;
                }
                
                QStatusBar {
                    background-color: #333;
                    color: #aaa;
                    border-top: 1px solid #444;
                }
                
                QScrollBar:vertical {
                    background: #333;
                    width: 12px;
                }
                
                QScrollBar::handle:vertical {
                    background: #555;
                    min-height: 20px;
                    border-radius: 6px;
                }
                
                QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                    height: 0px;
                }
                
                QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {
                    background: none;
                }
            """
            
            self.connect_button.setStyleSheet("background-color: #3a7c3a; color: white; padding: 8px;")
            self.clear_button.setStyleSheet("background-color: #8b3a3a; color: white; padding: 8px;")
            
            self.setStyleSheet(dark_style)
            self.theme_button.setText("Switch to Light Mode" if self.current_language == "en" else 
                                     "切换日间模式" if self.current_language == "zh" else 
                                     "ライトモードに切替")
        else:
            light_style = """
                QWidget {
                    background-color: #f5f5f5;
                    color: #333;
                    border: none;
                }
                
                QMainWindow {
                    background-color: #f0f0f0;
                }
                
                QGroupBox {
                    background-color: #f9f9f9;
                    color: #333;
                    border: 1px solid #ccc;
                    border-radius: 5px;
                    margin-top: 1ex;
                    padding-top: 10px;
                    font-weight: bold;
                }
                
                QGroupBox::title {
                    subcontrol-origin: margin;
                    subcontrol-position: top center;
                    padding: 0 5px;
                    background-color: #f9f9f9;
                    color: #333;
                }
                
                QTextEdit, QLineEdit, QComboBox, QCheckBox {
                    background-color: white;
                    color: #333;
                    border: 1px solid #ccc;
                    padding: 5px;
                    border-radius: 3px;
                }
                
                QPushButton {
                    background-color: #f0f0f0;
                    color: #333;
                    border: 1px solid #ccc;
                    padding: 8px;
                    border-radius: 4px;
                }
                
                QPushButton:hover {
                    background-color: #e6e6e6;
                }
                
                QPushButton:pressed {
                    background-color: #d9d9d9;
                }
                
                QPushButton:disabled {
                    background-color: #eee;
                    color: #999;
                }
                
                QRadioButton, QLabel {
                    color: #333;
                }
                
                QSplitter::handle {
                    background-color: #ddd;
                }
                
                QStatusBar {
                    background-color: #f0f0f0;
                    color: #666;
                    border-top: 1px solid #ddd;
                }
                
                QScrollBar:vertical {
                    background: #f0f0f0;
                    width: 12px;
                }
                
                QScrollBar::handle:vertical {
                    background: #d0d0d0;
                    min-height: 20px;
                    border-radius: 6px;
                }
                
                QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                    height: 0px;
                }
                
                QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {
                    background: none;
                }
            """
            
            self.connect_button.setStyleSheet("background-color: #4CAF50; color: white; padding: 8px;")
            self.clear_button.setStyleSheet("background-color: #f44336; color: white; padding: 8px;")
            
            self.setStyleSheet(light_style)
            self.theme_button.setText("Switch to Dark Mode" if self.current_language == "en" else 
                                     "切换夜间模式" if self.current_language == "zh" else 
                                     "ダークモードに切替")
    
    def log_message(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_output.append(f"[{timestamp}] {message}")
        self.log_output.verticalScrollBar().setValue(self.log_output.verticalScrollBar().maximum())
    
    def update_status(self):
        active_tunnels = []
        for local_port, process_info in self.processes.items():
            status = "Running" if process_info['process'].poll() is None else "Stopped"
            if self.current_language == "zh":
                status = "运行中" if status == "Running" else "已停止"
            elif self.current_language == "ja":
                status = "実行中" if status == "Running" else "停止"
                
            active_tunnels.append(f"Local port: {local_port} → Remote port: {process_info['remote_port']} ({status})")
        
        self.tunnels_list.clear()
        if active_tunnels:
            self.tunnels_list.append("\n".join(active_tunnels))
        else:
            if self.current_language == "en":
                self.tunnels_list.append("No active tunnels")
            elif self.current_language == "zh":
                self.tunnels_list.append("没有活动隧道")
            elif self.current_language == "ja":
                self.tunnels_list.append("アクティブなトンネルはありません")
        
        lang = {
            "en": {
                "active_tunnels": "Active Tunnels:",
                "last_operation": "Last Operation:",
                "mode": "Mode:",
                "auth": "Authentication:",
                "local_openssl": "Local OpenSSL:",
                "remote_info": "Remote Host Info:",
                "ip_address": "IP Address:",
                "hostname": "Hostname:",
                "os": "Operating System:",
                "remote_openssl": "Remote OpenSSL:"
            },
            "zh": {
                "active_tunnels": "活动隧道数量:",
                "last_operation": "最后操作:",
                "mode": "模式:",
                "auth": "认证方式:",
                "local_openssl": "本地OpenSSL:",
                "remote_info": "远程主机信息:",
                "ip_address": "IP地址:",
                "hostname": "主机名:",
                "os": "操作系统:",
                "remote_openssl": "远程OpenSSL:"
            },
            "ja": {
                "active_tunnels": "アクティブなトンネル:",
                "last_operation": "最後の操作:",
                "mode": "モード:",
                "auth": "認証方法:",
                "local_openssl": "ローカルOpenSSL:",
                "remote_info": "リモートホスト情報:",
                "ip_address": "IPアドレス:",
                "hostname": "ホスト名:",
                "os": "オペレーティングシステム:",
                "remote_openssl": "リモートOpenSSL:"
            }
        }
        
        lang_dict = lang[self.current_language]
        
        self.status_output.clear()
        self.status_output.append(f"{lang_dict['active_tunnels']} {len(self.processes)}")
        self.status_output.append(f"{lang_dict['last_operation']} {self.last_operation_time}")
        
        mode = "Local forwarding" if self.local_forward_radio.isChecked() else "Remote forwarding"
        if self.current_language == "zh":
            mode = "本地端口转发" if mode == "Local forwarding" else "远程端口转发"
        elif self.current_language == "ja":
            mode = "ローカルポート転送" if mode == "Local forwarding" else "リモートポート転送"
            
        self.status_output.append(f"{lang_dict['mode']} {mode}")
        
        auth = self.auth_method.currentText()
        self.status_output.append(f"{lang_dict['auth']} {auth}")
        self.status_output.append(f"{lang_dict['local_openssl']} {self.openssl_version}")
        
        if self.remote_info:
            self.status_output.append(f"\n{lang_dict['remote_info']}")
            self.status_output.append(f"{lang_dict['ip_address']} {self.remote_info.get('ip', 'Unknown')}")
            self.status_output.append(f"{lang_dict['hostname']} {self.remote_info.get('host', 'Unknown')}")
            self.status_output.append(f"{lang_dict['os']} {self.remote_info.get('os', 'Unknown')}")
            self.status_output.append(f"{lang_dict['remote_openssl']} {self.remote_info.get('openssl', 'Unknown')}")
    
    def parse_ports(self, port_str):
        mappings = []
        port_pairs = port_str.split(',')
        
        for pair in port_pairs:
            pair = pair.strip()
            if ':' in pair:
                try:
                    local, remote = pair.split(':')
                    mappings.append((int(local.strip()), int(remote.strip())))
                except ValueError:
                    self.log_message(f"Error: Invalid port mapping '{pair}'")
            else:
                try:
                    port = int(pair.strip())
                    mappings.append((port, port))
                except ValueError:
                    self.log_message(f"Error: Invalid port '{pair}'")
        
        return mappings
    
    def toggle_connection(self):
        if "Connect" in self.connect_button.text() or \
           "建立" in self.connect_button.text() or \
           "接続" in self.connect_button.text():
            self.create_tunnels()
        else:
            self.close_tunnels()
    
    def create_tunnels(self):
        server = self.server_input.text().strip()
        port_str = self.port_input.text().strip()
        auth_method = self.auth_method.currentText()
        
        if not server:
            self.log_message("Error: Please enter server address")
            return
        if not port_str:
            self.log_message("Error: Please enter port mapping")
            return
        
        if auth_method == "Certificate" or auth_method == "证书验证" or auth_method == "証明書認証":
            cert_path = self.cert_path_input.text().strip()
            if not cert_path:
                self.log_message("Error: Please select certificate file")
                return
            if not os.path.exists(cert_path):
                self.log_message(f"Error: Certificate file not found: {cert_path}")
                return
        else:
            username = self.username_input.text().strip()
            password = self.password_input.text().strip()
            if not username:
                self.log_message("Error: Please enter username")
                return
            if not password:
                self.log_message("Error: Please enter password")
                return
            if '@' in server:
                server_username, server_host = server.split('@', 1)
                server = f"{username}@{server_host}"
            else:
                server = f"{username}@{server}"
        
        port_mappings = self.parse_ports(port_str)
        if not port_mappings:
            self.log_message("Error: No valid port mappings")
            return
        
        options = []
        if self.verbose_check.isChecked():
            options.append("-v")
        if self.compression_check.isChecked():
            options.append("-C")
        if self.no_command_check.isChecked():
            options.append("-N")
        ssh_options = " ".join(options)
        
        is_local_forward = self.local_forward_radio.isChecked()
        
        if not self.remote_info:
            self.log_message("Getting remote host info...")
            self.remote_info = self.get_remote_info(server)
            if self.remote_info.get('ip', 'Unknown') != "Failed to get":
                self.log_message(f"Remote host info obtained: {self.remote_info.get('ip')}")
            else:
                self.log_message("Warning: Unable to get complete remote host info")
        
        self.last_operation_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        for local_port, remote_port in port_mappings:
            if is_local_forward:
                base_cmd = f"ssh {ssh_options} -L {local_port}:localhost:{remote_port}"
                direction = "Local"
            else:
                base_cmd = f"ssh {ssh_options} -R {remote_port}:localhost:{local_port}"
                direction = "Remote"
            
            if auth_method == "Certificate" or auth_method == "证书验证" or auth_method == "証明書認証":
                cert_path = self.cert_path_input.text().strip()
                cmd = f"{base_cmd} -i \"{cert_path}\" {server}"
            else:
                cmd = f"{base_cmd} {server}"
            
            self.log_message(f"Creating {direction} tunnel: Local port {local_port} → Remote port {remote_port}")
            self.log_message(f"Command: {cmd}")
            
            try:
                process = subprocess.Popen(
                    cmd,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True
                )
                
                self.processes[local_port] = {
                    'process': process,
                    'cmd': cmd,
                    'remote_port': remote_port,
                    'direction': direction,
                    'auth_method': auth_method
                }
                
                threading.Thread(
                    target=self.read_process_output,
                    args=(process, local_port, remote_port),
                    daemon=True
                ).start()
                
            except Exception as e:
                self.log_message(f"Error: Failed to create tunnel - {str(e)}")
        
        lang = {
            "en": "Connect",
            "zh": "建立连接",
            "ja": "接続"
        }
        self.connect_button.setText(lang[self.current_language])
        self.connect_button.setStyleSheet("background-color: #f44336; color: white; padding: 8px;" if not self.dark_mode else "background-color: #8b3a3a; color: white; padding: 8px;")
        self.log_message("Tunnels created successfully")
    
    def read_process_output(self, process, local_port, remote_port):
        direction = "Local" if self.local_forward_radio.isChecked() else "Remote"
        
        while True:
            output = process.stdout.readline()
            if output:
                self.log_message(f"[Port {local_port}→{remote_port}] {output.strip()}")
            
            err_output = process.stderr.readline()
            if err_output:
                self.log_message(f"[Port {local_port}→{remote_port} Error] {err_output.strip()}")
            
            if process.poll() is not None:
                if local_port in self.processes:
                    del self.processes[local_port]
                
                self.last_operation_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                self.log_message(f"Tunnel closed: Local port {local_port} → Remote port {remote_port}")
                break
    
    def close_tunnels(self):
        self.log_message("Closing all tunnels...")
        
        self.last_operation_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        for local_port, info in list(self.processes.items()):
            try:
                info['process'].terminate()
                self.log_message(f"Closed tunnel: Local port {local_port} → Remote port {info['remote_port']}")
            except Exception as e:
                self.log_message(f"Tunnel close error: {str(e)}")
        
        self.processes.clear()
        
        self.remote_info = {}
        
        lang = {
            "en": "Connect",
            "zh": "建立连接",
            "ja": "接続"
        }
        self.connect_button.setText(lang[self.current_language])
        self.connect_button.setStyleSheet("background-color: #4CAF50; color: white; padding: 8px;" if not self.dark_mode else "background-color: #3a7c3a; color: white; padding: 8px;")
        self.log_message("All tunnels closed")
    
    def clear_fields(self):
        self.server_input.clear()
        self.port_input.clear()
        self.username_input.clear()
        self.password_input.clear()
        self.cert_path_input.clear()
        
        lang = {
            "en": "Fields cleared",
            "zh": "输入字段已清空",
            "ja": "フィールドをクリアしました"
        }
        self.log_message(lang[self.current_language])
        
        self.remote_info = {}
        
        self.verbose_check.setChecked(False)
        self.compression_check.setChecked(False)
        self.no_command_check.setChecked(False)
    
    def closeEvent(self, event):
        if self.processes:
            self.close_tunnels()
        event.accept()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle(QStyleFactory.create("Fusion"))
    manager = SSHManager()
    manager.show()
    sys.exit(app.exec_())
