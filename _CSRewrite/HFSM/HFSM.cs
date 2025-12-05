using Godot;
using System.Collections.Generic;
using System;
namespace CharacterControl
{
    public abstract class HFSMState<T> where T : class
    {
        protected HFSM<T> Machine;
        protected T Agent;
        public HFSMState<T> Parent;

        public virtual void Initialise(HFSM<T> machine, T agent, HFSMState<T> parent = null)
        {
            Machine = machine;
            Agent = agent;
            Parent = parent;
        }
        public virtual void Enter() { }
        public virtual void Exit() { }
        public virtual void Update(double delta) { }
        public virtual void PhysicsUpdate(double delta) { }

        // Returns true if the event was consumed
        public virtual bool HandleEvent(ActionEvent evt) 
        {
            return Parent?.HandleEvent(evt) ?? false;
        }

        // Default: Ask the parent, or return a "Do Nothing" instruction
        public virtual LocomotionInstruction GetLocomotionInstruction()
        {
            return Parent?.GetLocomotionInstruction() ?? new LocomotionInstruction(0);
        }

    }
    public class HFSM<T>(T agent, string name = "HFSM") where T: class
    {
        private readonly Dictionary<Type, HFSMState<T>>  _states = new();
        private readonly List<HFSMState<T>> _currentPath = new();
        private readonly List<HFSMState<T>> _newPath = new();

        public HFSMState<T> CurrentState {get;private set;}

        public T Agent { get; private set; } = agent;

        //debugging
        public string DebugName { get; set; } = name;
        public bool DebugMode{get;set;}

        public void AddState(HFSMState<T> state, Type parentType = null)
        {
            HFSMState<T> parent = null;
            if (parentType != null && _states.TryGetValue(parentType, out var _parent))
            {
                parent = _parent;
            }
            state.Initialise(this, Agent, parent);
            _states[state.GetType()] = state;
        }
        public void Init(Type startStateType)
        {
            ChangeState(startStateType);
        }
        public void ChangeState<TState>() where TState : HFSMState<T>
        {
            ChangeState(typeof(TState));
        }
        // public void ChangeState(Type newStateType)
        // {
        //     if(!_states.TryGetValue(newStateType, out var newState)) return;
        //     if(CurrentState == newState) return;

        //     if (DebugMode) GD.Print($"[{DebugName}] {CurrentState?.GetType().Name} -> {newState.GetType().Name}");

        //     // Simple transition: Exit old -> Enter new
        //     // (implement finding common ancestor later)
        //     CurrentState?.Exit();
        //     CurrentState = newState;
        //     CurrentState.Enter();
        // }


        // try to learn about this algorithm later
        public void ChangeState(Type newStateType)
        {
            if (!_states.TryGetValue(newStateType, out var newState)) 
            {
                GD.PushWarning($"[{DebugName}] State not found: {newStateType.Name}");
                return;
            }
            
            // 1. Handle Self-Transition (Optional: allow re-entry or ignore)
            if (CurrentState == newState) return;

            if (DebugMode) GD.Print($"[{DebugName}] {CurrentState?.GetType().Name} -> {newState.GetType().Name}");

            // 2. Find the ancestry path for both states
            // Result is [Root, Child, Grandchild...]
            FillPathToRoot(CurrentState, _currentPath);
            FillPathToRoot(newState, _newPath);

            // 3. Find the Lowest Common Ancestor (LCA) index
            int commonAncestorIndex = 0;
            
            // Iterate while both paths have nodes and they are equal
            while (commonAncestorIndex < _currentPath.Count && 
                commonAncestorIndex < _newPath.Count && 
                _currentPath[commonAncestorIndex] == _newPath[commonAncestorIndex])
            {
                commonAncestorIndex++;
            }
            
            // At this point, commonAncestorIndex is the first index where they DIFFER.
            // The actual Common Ancestor is at commonAncestorIndex - 1.
            // We do NOT exit/enter the Common Ancestor.

            // 4. EXIT the old branch (From bottom up to the split point)
            // We iterate backwards from the active child up to the divergence
            for (int i = _currentPath.Count - 1; i >= commonAncestorIndex; i--)
            {
                _currentPath[i].Exit();
            }

            // 5. Update Current State
            CurrentState = newState;

            // 6. ENTER the new branch (From the split point down to the leaf)
            for (int i = commonAncestorIndex; i < _newPath.Count; i++)
            {
                _newPath[i].Enter();
            }
            
            // Cleanup lists to keep them ready for next time
            _currentPath.Clear();
            _newPath.Clear();
        }

        // Helper to build the lineage list: [Root, Child, GrandChild]
        private static void FillPathToRoot(HFSMState<T> startNode, List<HFSMState<T>> outList)
        {
            outList.Clear();
            if (startNode == null) return;

            var current = startNode;
            while (current != null)
            {
                outList.Add(current);
                current = current.Parent;
            }
            
            // The loop adds them [Leaf, Parent, Root]. We need [Root, Parent, Leaf].
            outList.Reverse();
        }

        public void Update(double delta) => CurrentState?.Update(delta);
        public void PhysicsUpdate(double delta) => CurrentState?.PhysicsUpdate(delta);
        
        public bool HandleEvent(ActionEvent evt) => CurrentState?.HandleEvent(evt) ?? false;
        
        public LocomotionInstruction GetInstruction() => 
            CurrentState?.GetLocomotionInstruction() ?? new LocomotionInstruction(0);
    }
}