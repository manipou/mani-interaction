<script lang="ts">
	import Visualizer from "$lib/components/visualizer.svelte";
	import VisibilityProvider from "$lib/providers/VisibilityProvider.svelte";
	import { ShowVisualizer, ShowRadialMenu } from "$lib/stores/VisibilityStore";
	import RadialMenu from "$lib/components/radial.svelte";
</script>

<link
  rel="stylesheet"
  href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
/>

<VisibilityProvider >
	{#if $ShowVisualizer}
		<Visualizer />
	{/if}
	{#if $ShowRadialMenu}
		<RadialMenu />
	{/if}
</VisibilityProvider>
