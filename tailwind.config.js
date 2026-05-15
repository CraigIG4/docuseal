module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        // IGSIGN brand theme — Ignition Group CI, Brand Bible v1
        // data-theme="IGSIGN" is set on all layouts; the key must match exactly.
        IGSIGN: {
          'color-scheme': 'light',
          primary: '#162B3C',      // Arctic Black  — PANTONE 303 C
          secondary: '#7B787F',    // Cool Grey     — PANTONE Cool Grey 9 C
          accent: '#45AC34',       // Innovation Green — PANTONE 361 C
          neutral: '#0d1f2d',      // deep near-black for dark surfaces
          'base-100': '#ffffff',   // page background
          'base-200': '#f5f7f9',   // raised surface
          'base-300': '#e8ebed',   // borders / dividers
          'base-content': '#162B3C',
          '--rounded-btn': '0.375rem',
          '--tab-border': '2px',
          '--tab-radius': '.375rem'
        }
      }
    ]
  }
}
