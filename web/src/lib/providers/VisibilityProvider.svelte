<script lang="ts">
	import { ShowVisualizer, visibilityStore as visibility, Options, ShowRadialMenu } from "$lib/stores/VisibilityStore";
	import { useNuiEvent } from "$lib/hooks/useNuiEvent";

	useNuiEvent<boolean>("setVisible", (visible) => {
		visibility.toggle(visible);
	});

	useNuiEvent<boolean>("SetVisualizer", (visible) => {
		visibility.toggle(visible);
		ShowVisualizer.set(visible);
	});

	useNuiEvent<boolean>("OpenRadial", (InteractionOptions) => {
		visibility.show();
		ShowRadialMenu.set(true);
		Options.set(InteractionOptions);
	});

	useNuiEvent<boolean>("CloseRadial", () => {
		visibility.hide();
		ShowRadialMenu.set(false);
		Options.set([]);
	});
</script>

{#if $visibility}
	<slot />
{/if}