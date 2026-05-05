<template>
  <svg
    height="40"
    width="40"
    viewBox="0 0 112 112"
    xmlns="http://www.w3.org/2000/svg"
  >
    <!-- Hexagon fill - clean, no dot/tick -->
    <polygon points="56,4 100,28 100,78 56,102 12,78 12,28" fill="#162B3C"/>
    <polygon points="56,4 100,28 100,78 56,102 12,78 12,28" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>
    <!-- IG text only -->
    <text x="56" y="56" text-anchor="middle" dominant-baseline="central"
          font-family="Avenir,'DM Sans',Arial,sans-serif" font-weight="800" font-size="36" fill="#FFFFFF" letter-spacing="2">IG</text>
  </svg>
</template>

<script>
export default {
  name: 'ProjectLogo'
}
</script>
