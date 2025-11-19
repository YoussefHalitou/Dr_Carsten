import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          500: '#667eea',
          600: '#5a67d8'
        },
        secondary: {
          500: '#764ba2'
        }
      },
      boxShadow: {
        chat: '0 8px 32px rgba(0, 0, 0, 0.12)'
      },
      keyframes: {
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        typing: {
          '0%, 60%, 100%': { transform: 'translateY(0)' },
          '30%': { transform: 'translateY(-10px)' }
        }
      },
      animation: {
        slideUp: 'slideUp 0.3s ease',
        fadeIn: 'fadeIn 0.3s ease',
        typing: 'typing 1.4s infinite'
      }
    }
  },
  plugins: []
};

export default config;
