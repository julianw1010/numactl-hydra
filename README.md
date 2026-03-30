# numactl-hydra

A fork of [numactl](https://github.com/numactl/numactl) that adds command-line support for Hydra page table replication. It requires the [Hydra kernel](https://github.com/julianw1010/hydra-6.4.0-fork).

## Building

```bash
./install.sh
```

Build dependencies (autoconf, automake, libtool, etc.) are installed automatically.

## Page Table Replication

The `--pgtablerepl` (`-r`) option enables page table replication for a launched process. The argument specifies which NUMA nodes should hold replicas.

```bash
# Replicate across all online NUMA nodes
numactl --pgtablerepl=all ./my_application

# Replicate across nodes 0 and 1
numactl --pgtablerepl=0,1 ./my_application

# Replicate across a range of nodes
numactl --pgtablerepl=0-3 ./my_application
```

The node specification uses the same syntax as other numactl options: comma-separated node numbers, ranges with dashes, or `all`. Nodes can be inverted with `!` and made cpuset-relative with `+`.

Replication is applied after all other policy options have been processed and before the command is executed via `execvp`. This means it can be combined with existing numactl options:

```bash
numactl --interleave=all --pgtablerepl=all ./my_application
numactl --membind=0,1 --cpunodebind=0,1 --pgtablerepl=0,1 ./my_application
```

## How It Works

The `--pgtablerepl` option calls `numa_set_pgtable_replication_mask()` from libnuma, which issues a `set_pgtblreplpolicy` system call (syscall 400). The kernel then allocates replica page tables on each specified node, migrates the existing page table tree to the primary node, and switches each CPU to its node-local replica via CR3 writes.

The option is applied only after confirming a valid command is present on the command line. If the command is missing, numactl prints usage information and exits without modifying any state.

## libnuma API Additions

This fork adds the following functions to libnuma:

```c
/* Enable page table replication on the specified nodes.
   Pass numa_no_nodes_ptr to disable. */
void numa_set_pgtable_replication_mask(struct bitmask *nodemask);

/* Query the current replication mask. Returns a bitmask that the
   caller must free with numa_bitmask_free(). */
struct bitmask *numa_get_pgtable_replication_mask(void);
```

These are exported in `libnuma_1.5` in the versioning script.

## Compatibility

All existing numactl functionality is preserved. The added option and library functions are only meaningful on kernels with the Hydra patch applied. On unpatched kernels, the syscall will return an error and numactl will report the failure.

## License

numactl is dual-licensed: libnuma under LGPL 2.1, numactl binaries under GPL 2. See LICENSE.GPL2 and LICENSE.LGPL2.1.
