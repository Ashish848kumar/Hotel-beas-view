import type { Config } from 'tailwindcss';
export default { content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}', './data/**/*.{js,ts,jsx,tsx}'], theme: { extend: { colors: { forest: '#183a32', cream: '#f6f3ed' }, fontFamily: { sans: ['Arial', 'sans-serif'], serif: ['Georgia', 'serif'] } } }, plugins: [] } satisfies Config;
