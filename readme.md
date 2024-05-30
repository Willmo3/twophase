# Twophase

## Introduction
This is a TLA+ specification of the two phase commit protocol for distributed consensus.

### Credit 
CMU SoDA's implementation heavily inspired my work. See at https://github.com/cmu-soda/recomp-verify/blob/master/benchmarks/tla/two_phase/9/TwoPhase.tla!

Leslie Lamport's TLA+ video series scaffolded me. (See it on lamport.org)

## The Algorithm
Consider a consistent operation in a distributed system, like a database commit over several resource managers. By definition, a consistent operation must effect all nodes uniformly. Yet in a distributed system, where "the failure of a computer you didn't even know existed can render your computer unusable" (Lamport), this can't be taken for granted.

To negate this risk, two phase commit obeys the following invariant.

### The Invariant
For any two nodes N1 and N2, if N1 is committed, then N2 is not aborted.

### The implementation
(Note: we consider a simplified version of two-phase commit)

In two phase commit, a central node tracks how many worker nodes are prepared to make a commit.

At any point, a worker node may declare itself prepared to commit a change to the central node.

Once each node has declared itself prepared, the first phase of two phase commit is over! 

The central node now declares the change committed and messages this to each worker node.

Finally, when each node receives an explicit commit message from the main node, it declares the change committed.

### Why it works
What can go wrong here? 

Suppose a worker node is unreachable. In a poorly implemented system, the central node might declare a change committed without this node knowing. Now consistency has been violated!

However, with two-phase commit, changes can only be committed when the transaction manager receives explicit confirmation from each and every node. Even a silent failure cannot threaten consistency!

And while the central node is a single point of failure, if it goes offline, the worker nodes cannot commit their changes.

Our algorithm isn't foolproof -- a worker node might miss the main node's explicit commit message, for instance. A more detailed exploration of two phase commit would address this.
