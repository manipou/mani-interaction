<script lang="ts">
	import { Options, visibilityStore as visibility } from "$lib/stores/VisibilityStore";
	import { fetchNui } from "$lib/utils/fetchNui";
	import { useNuiEvent } from "$lib/hooks/useNuiEvent";
  import { onMount, onDestroy } from "svelte";

  function onSelect(index: number) {
    visibility.hide();
    fetchNui("onRadialSelect", index + 1);
  }

  useNuiEvent("selectCurrentOption", () => {
		visibility.hide();
    if (hoveredIndex !== null) {
      fetchNui("onRadialSelect", hoveredIndex + 1);
    } else {
      fetchNui("onCancel");
    }
	});

  function onCancel() {
    visibility.hide();
    fetchNui("onCancel");
  }

  const outerRadius = 150;
  const innerRadius = 30;
  const hoverExtra = 10;
  const angleStep = 360 / $Options.length;

  let hoveredIndex: number | null = null;
  let svgEl: SVGSVGElement;

  function getPath(index: number, expand = 0) {
    const radius = outerRadius + expand;
    const startAngle = (index * angleStep - 90) * (Math.PI / 180);
    const endAngle = ((index + 1) * angleStep - 90) * (Math.PI / 180);

    const x1 = 150 + radius * Math.cos(startAngle);
    const y1 = 150 + radius * Math.sin(startAngle);
    const x2 = 150 + radius * Math.cos(endAngle);
    const y2 = 150 + radius * Math.sin(endAngle);

    const x3 = 150 + innerRadius * Math.cos(endAngle);
    const y3 = 150 + innerRadius * Math.sin(endAngle);
    const x4 = 150 + innerRadius * Math.cos(startAngle);
    const y4 = 150 + innerRadius * Math.sin(startAngle);

    const largeArc = angleStep > 180 ? 1 : 0;

    return `
      M ${x1} ${y1}
      A ${radius} ${radius} 0 ${largeArc} 1 ${x2} ${y2}
      L ${x3} ${y3}
      A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${x4} ${y4}
      Z
    `;
  }

  function getLabelPos(index: number) {
    const angle = ((index + 0.5) * angleStep - 90) * (Math.PI / 180);
    const radius = (outerRadius + innerRadius) / 2;
    return {
      x: 150 + radius * Math.cos(angle),
      y: 150 + radius * Math.sin(angle),
    };
  }

  function getIndexFromMouse(event: MouseEvent) {
    const rect = svgEl.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;

    const dx = event.clientX - cx;
    const dy = event.clientY - cy;
    const distance = Math.sqrt(dx * dx + dy * dy);

    hoveredIndex =
      distance < innerRadius
        ? null
        : Math.floor(((Math.atan2(dy, dx) * 180) / Math.PI + 450) % 360 / angleStep);
  }

  function handleClick() {
    if (hoveredIndex !== null) onSelect(hoveredIndex);
  }

  onMount(() => {
    window.addEventListener("mousemove", getIndexFromMouse);
    window.addEventListener("click", handleClick);
  });

  onDestroy(() => {
    window.removeEventListener("mousemove", getIndexFromMouse);
    window.removeEventListener("click", handleClick);
  });
</script>

<div class="min-h-screen flex items-center justify-center relative">
  <svg
    bind:this={svgEl}
    width="300"
    height="300"
    viewBox="0 0 300 300"
    style="overflow: visible;"
  >
    <defs>
      <radialGradient id="glassGradient" cx="50%" cy="50%" r="70%">
        <stop offset="0%" stop-color="#1e293b" stop-opacity="0.4" />
        <stop offset="100%" stop-color="#0f172a" stop-opacity="0.3" />
      </radialGradient>
    
      <linearGradient id="hoverBlueGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="rgba(96,165,250,0.3)" />
        <stop offset="100%" stop-color="rgba(59,130,246,0.3)" />
      </linearGradient>
    
      <radialGradient id="cancelGradient" cx="50%" cy="50%" r="70%">
        <stop offset="0%" stop-color="#1e293b" stop-opacity="0.9" />
        <stop offset="100%" stop-color="#0f172a" stop-opacity="0.8" />
      </radialGradient>
    </defs>
    
    <!-- Wedges -->
    {#each $Options as item, i}
      <path
        d={getPath(i, hoveredIndex === i ? hoverExtra : 0)}
        class="cursor-pointer transition-all duration-300"
        fill={hoveredIndex === i ? "url(#hoverBlueGradient)" : "url(#glassGradient)"}
        stroke="white"
        stroke-opacity="0.2"
      />
    {/each}

    <!-- Icons + labels centered perfectly -->
    {#each $Options as item, i}
      <g
        transform="translate({getLabelPos(i).x}, {getLabelPos(i).y}) scale({hoveredIndex === i ? 1.2 : 1})"
        style="transform-box: fill-box; transform-origin: center; transition: transform 0.2s ease;"
      >
        <foreignObject x="-32" y="-24" width="64" height="48">
          <div class="flex flex-col items-center justify-center w-full h-full pointer-events-none">
            <i class={item.icon + " text-lg text-white drop-shadow-[0_0_2px_RGBA(0,0,0,0.3)]"}></i>
            <span class="text-sm font-bold text-white drop-shadow-[0_0_2px_RGBA(0,0,0,0.3)]">{item.label}</span>
          </div>
        </foreignObject>
      </g>
    {/each}

    <!-- Cancel button -->
    <circle
      cx="150"
      cy="150"
      r={innerRadius}
      fill="url(#cancelGradient)"
      class="stroke-white/30 cursor-pointer transition hover:stroke-blue-400 hover:stroke-2"
      on:click={onCancel}
    />
    <text
      x="150"
      y="155"
      text-anchor="middle"
      class="fill-white font-extrabold text-lg pointer-events-none"
    >✕</text>
  </svg>
</div>

<style>
  * {
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }
</style>