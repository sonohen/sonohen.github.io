(() => {
    const block = document.querySelector('[data-sidebar-navigation]');
    if (!block) return;
    const update = () => block.classList.toggle('can-stick', block.getBoundingClientRect().height <= window.innerHeight - 48);
    new ResizeObserver(update).observe(block);
    window.addEventListener('resize', update);
    update();
})();
