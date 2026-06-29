# numactl-hydra

A fork of [numactl](https://github.com/numactl/numactl) that adds command-line support for Hydra page table replication. It requires the [Hydra kernel](https://github.com/julianw1010/hydra-6.4.0-fork).

## Building

```bash
./install.sh
```

Build dependencies (autoconf, automake, libtool, etc.) are installed automatically.

## Page Table Replication

The `--pgtablerepl` (`-r`) option enables page table replication for a launched process. It takes no argument: replicas are created on every NUMA node.

```bash
# Replicate page tables across all NUMA nodes
numactl --pgtablerepl ./my_application
numactl -r ./my_application
```

Replication is applied after all other policy options have been processed and before the command is executed via `execvp`. This means it can be combined with existing numactl options:

```bash
numactl --interleave=all --pgtablerepl ./my_application
numactl --membind=0,1 --cpunodebind=0,1 --pgtablerepl ./my_application
```

## How It Works

The `--pgtablerepl` option calls `numa_set_pgtable_replication()` from libnuma, which issues a `set_pgtblreplpolicy` system call (syscall 400) with no arguments. The kernel then allocates replica page tables on every node, migrates the existing page table tree to the primary node, and switches each CPU to its node-local replica via CR3 writes.

The option is applied only after confirming a valid command is present on the command line. If the command is missing, numactl prints usage information and exits without modifying any state.

## libnuma API Additions

This fork adds the following functions to libnuma:

```c
/* Enable page table replication on all NUMA nodes. */
void numa_set_pgtable_replication(void);

/* Query the current replication mask. Returns a bitmask that the
   caller must free with numa_bitmask_free(). */
struct bitmask *numa_get_pgtable_replication_mask(void);
```

These are exported in `libnuma_1.5` in the versioning script.

## Compatibility

All existing numactl functionality is preserved. The added option and library functions are only meaningful on kernels with the Hydra patch applied. On unpatched kernels, the syscall will return an error and numactl will report the failure.

## License

numactl is dual-licensed: libnuma under LGPL 2.1, numactl binaries under GPL 2. See LICENSE.GPL2 and LICENSE.LGPL2.1.
