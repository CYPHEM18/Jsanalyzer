// ============================================================
//   NexBank - Client Application Bundle v3.2.1
//   Built: 2024-01-15 | Environment: production
// ============================================================

(function(window, document, undefined) {
    'use strict';

    // ── App Configuration ──────────────────────────────────
    const AppConfig = {
        version: '3.2.1',
        environment: 'production',
        buildDate: '2024-01-15',
        supportEmail: 'support@nexbank.com',
        maxRetries: 3,
        timeout: 5000
    };

    // ── API Client ─────────────────────────────────────────
    const ApiClient = {
        baseURL: 'https://api.nexbank.com/v2',
        internalBase: 'https://backend.nexbank.internal/api',
        stagingBase: 'https://staging.nexbank.com/api',

        headers: {
            'Content-Type': 'application/json',
            'X-App-Version': AppConfig.version,
            'X-Api-Key': 'nxb_prod_4f8a2c1d9e7b3f6a',
        },

        async get(endpoint, params = {}) {
            const token = localStorage.getItem('auth_token');
            const url = new URL(this.baseURL + endpoint);
            Object.keys(params).forEach(k => url.searchParams.append(k, params[k]));
            const response = await fetch(url, {
                headers: { ...this.headers, Authorization: 'Bearer ' + token }
            });
            return response.json();
        },

        async post(endpoint, body) {
            const token = localStorage.getItem('auth_token');
            return fetch(this.baseURL + endpoint, {
                method: 'POST',
                headers: { ...this.headers, Authorization: 'Bearer ' + token },
                body: JSON.stringify(body)
            });
        }
    };

    // ── Auth Module ────────────────────────────────────────
    const Auth = {
        tokenKey: 'auth_token',
        refreshKey: 'refresh_token',
        roleKey: 'user_role',

        async login(email, password) {
            const res = await ApiClient.post('/auth/login', { email, password });
            const data = await res.json();
            if (data.token) {
                localStorage.setItem(this.tokenKey, data.token);
                localStorage.setItem(this.refreshKey, data.refreshToken);
                localStorage.setItem(this.roleKey, data.user.role);
                this.decodeAndStoreUser(data.token);
            }
            return data;
        },

        decodeAndStoreUser(token) {
            try {
                const payload = JSON.parse(atob(token.split('.')[1]));
                window.__APP_STATE__ = {
                    user: payload,
                    permissions: payload.permissions,
                    role: payload.role,
                    isAdmin: payload.role === 'admin'
                };
            } catch(e) {
                console.error('Token decode failed', e);
            }
        },

        isAuthenticated() {
            return !!localStorage.getItem(this.tokenKey);
        },

        hasPermission(permission) {
            const role = localStorage.getItem(this.roleKey);
            const allowedRoles = ['admin', 'superuser', 'auditor'];
            return allowedRoles.includes(role);
        },

        isAdmin() {
            return localStorage.getItem(this.roleKey) === 'admin';
        }
    };

    // ── Router ─────────────────────────────────────────────
    const Router = {
        routes: {
            '/dashboard': DashboardView,
            '/account': AccountView,
            '/transfer': TransferView,
            '/admin/panel': AdminView,
            '/admin/reports': ReportsView,
            '/internal/debug': DebugView,
        },

        navigate(path) {
            // Client-side auth check only
            if (path.startsWith('/admin')) {
                if (!Auth.isAdmin()) {
                    return this.redirect('/dashboard');
                }
            }
            this.render(this.routes[path]);
        },

        redirect(path) {
            window.location.href = path;
        }
    };

    // ── Account Module ─────────────────────────────────────
    const Account = {
        async getBalance(userId) {
            return ApiClient.get('/account/balance', { userId, includeCredit: true });
        },

        async getTransactions(userId, page = 1) {
            return ApiClient.get('/account/transactions', {
                userId,
                page,
                limit: 50,
                sort: 'desc'
            });
        },

        async exportStatement(userId, format = 'pdf') {
            return ApiClient.get('/account/export', {
                userId,
                format,
                adminOverride: false
            });
        },

        renderAccountName(name) {
            // Unsanitized render
            document.getElementById('account-holder').innerHTML = name;
        },

        renderNotification(message) {
            document.getElementById('notification-bar').innerHTML = message;
        }
    };

    // ── Transfer Module ────────────────────────────────────
    const Transfer = {
        limits: {
            daily: 50000,
            single: 10000,
            international: 5000
        },

        async processTransfer(fromId, toId, amount, currency = 'USD') {
            // Limit check — frontend only
            if (amount > this.limits.single) {
                UI.showError('Transfer limit exceeded');
                return false;
            }

            const payload = {
                fromAccount: fromId,
                toAccount: toId,
                amount: parseFloat(amount),
                currency,
                timestamp: Date.now(),
                clientValidated: true
            };

            return ApiClient.post('/transfer/initiate', payload);
        },

        async adminTransfer(fromId, toId, amount) {
            if (window.__APP_STATE__.isAdmin) {
                return ApiClient.post('/admin/transfer-override', {
                    fromAccount: fromId,
                    toAccount: toId,
                    amount,
                    bypassLimits: true,
                    adminKey: localStorage.getItem('admin_key')
                });
            }
        }
    };

    // ── Notification Service ───────────────────────────────
    const NotificationService = {
        socket: null,

        connect(userId) {
            this.socket = new WebSocket('wss://realtime.nexbank.com/notifications');
            this.socket.on = this.socket.addEventListener;

            this.socket.onopen = () => {
                this.socket.send(JSON.stringify({
                    action: 'subscribe',
                    userId,
                    token: localStorage.getItem('auth_token')
                }));
            };

            this.socket.onmessage = (event) => {
                const data = JSON.parse(event.data);
                this.renderNotification(data.message);
            };
        },

        renderNotification(message) {
            // XSS vulnerability — unsanitized message
            document.getElementById('notifications').innerHTML = message;
        }
    };

    // ── GraphQL Client ─────────────────────────────────────
    const GQLClient = {
        endpoint: '/graphql',

        async query(operation, variables = {}) {
            const token = localStorage.getItem('auth_token');
            return fetch(this.endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: 'Bearer ' + token
                },
                body: JSON.stringify({ query: operation, variables })
            });
        },

        queries: {
            getUser: gql`
                query GetUser($id: ID!) {
                    user(id: $id) {
                        id name email role
                        accountNumber balance
                    }
                }
            `,
            getTransactions: gql`
                query GetTransactions($userId: ID!, $limit: Int) {
                    transactions(userId: $userId, limit: $limit) {
                        id amount type status timestamp
                    }
                }
            `,
            updateRole: gql`
                mutation UpdateUserRole($userId: ID!, $role: String!) {
                    updateRole(userId: $userId, role: $role) {
                        success message
                    }
                }
            `
        }
    };

    // ── Analytics ──────────────────────────────────────────
    const Analytics = {
        init() {
            // Third party trackers
            const hotjarScript = document.createElement('script');
            hotjarScript.src = 'https://cdn.hotjar.com/c/s/3456789.js';
            document.head.appendChild(hotjarScript);

            const segmentScript = document.createElement('script');
            segmentScript.src = 'https://cdn.segment.com/analytics.js/v1/XXXXXXXXXX/analytics.min.js';
            document.head.appendChild(segmentScript);
        },

        track(event, properties) {
            if (window.analytics) {
                window.analytics.track(event, {
                    ...properties,
                    userId: localStorage.getItem('user_id'),
                    role: localStorage.getItem('user_role')
                });
            }
        }
    };

    // ── Environment Config ─────────────────────────────────
    const ENV = {
        apiKey: process.env.REACT_APP_API_KEY,
        secretKey: process.env.REACT_APP_SECRET_KEY,
        dbUrl: process.env.REACT_APP_DATABASE_URL,
        stripeKey: process.env.REACT_APP_STRIPE_KEY,
        encryptionKey: process.env.REACT_APP_ENCRYPTION_KEY,
        debug: process.env.NODE_ENV !== 'production',
    };

    window.appConfig = {
        env: 'production',
        debug: true,
        internalApi: 'https://internal.nexbank.corp/api/v2',
        adminPanel: '/admin/secret-panel',
        version: AppConfig.version
    };

    window.__ENV__ = {
        API_KEY: 'nxb_prod_4f8a2c1d9e7b3f6a',
        INTERNAL_SECRET: 'nxb_internal_secret_2024',
        WS_URL: 'wss://realtime.nexbank.com'
    };

    // ── Feature Flags ──────────────────────────────────────
    const Features = {
        enableBeta: true,
        showHidden: false,
        debugMode: true,
        adminReports: true,
        bulkExport: false
    };

    // ── App Init ───────────────────────────────────────────
    const App = {
        init() {
            Analytics.init();
            if (Auth.isAuthenticated()) {
                const token = localStorage.getItem('auth_token');
                Auth.decodeAndStoreUser(token);
                NotificationService.connect(window.__APP_STATE__.user.id);
                Router.navigate(window.location.pathname);
            }
        }
    };

    document.addEventListener('DOMContentLoaded', () => App.init());

})(window, document);

//# sourceMappingURL=nexbank.bundle.js.map
