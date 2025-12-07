using Godot;
using System.Collections.Generic;
using System;
using System.Text;

namespace CharacterControl
{
    public abstract class HFSMState<T> where T : class
    {
        protected HFSM<T> Machine;
        protected T Agent;
        
        // Public so we can assign it during setup
        public HFSMState<T> Parent { get; set; } 

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

        // Event Handling: Recursive Bubble Up
        public virtual bool HandleEvent(ActionEvent evt) 
        {
            // If I don't handle it, ask my parent.
            return Parent?.HandleEvent(evt) ?? false;
        }

        public virtual LocomotionInstruction GetLocomotionInstruction()
        {
            return Parent?.GetLocomotionInstruction() ?? new LocomotionInstruction(0);
        }
        public override string ToString()
        {
            return this.GetType().Name; 
        }

    }

    public class HFSM<T>(T agent, string name = "HFSM") where T : class
    {
        private readonly Dictionary<Type, HFSMState<T>> _states = new();
        
        // Transition Caches (Reuse lists to avoid GC)
        private readonly List<HFSMState<T>> _currentPath = new();
        private readonly List<HFSMState<T>> _newPath = new();

        public HFSMState<T> CurrentState { get; private set; }
        public T Agent { get; private set; } = agent;

        // --- DEBUGGING ---
        public string DebugName { get; set; } = name;
        public bool DebugMode { get; set; }
        
        private readonly LinkedList<string> _history = new(); // LinkedList is efficient for PushFront/PopBack
        private const int HISTORY_LIMIT = 10;

        public void AddState(HFSMState<T> state, Type parentType = null)
        {
            HFSMState<T> parent = null;
            if (parentType != null && _states.TryGetValue(parentType, out var p))
            {
                parent = p;
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

        public void ChangeState(Type newStateType)
        {
            if (!_states.TryGetValue(newStateType, out var newState))
            {
                GD.PushWarning($"[{DebugName}] State not found: {newStateType.Name}");
                return;
            }

            // 1. Handle Self-Transition
            if (CurrentState == newState) return;

            // 2. Find Ancestry Paths
            FillPathToRoot(CurrentState, _currentPath);
            FillPathToRoot(newState, _newPath);

            // 3. Find LCA (Lowest Common Ancestor)
            int commonAncestorIndex = 0;
            while (commonAncestorIndex < _currentPath.Count &&
                   commonAncestorIndex < _newPath.Count &&
                   _currentPath[commonAncestorIndex] == _newPath[commonAncestorIndex])
            {
                commonAncestorIndex++;
            }

            // 4. Debug Logging (Before we change state, capturing the transition)
            if (DebugMode)
            {
                // Format: [Loco] Grounded -> Idle  >>>  Grounded -> Walk
                string oldPathStr = FormatPathString(_currentPath);
                string newPathStr = FormatPathString(_newPath);
                string log = $"[{DebugName}] {oldPathStr} >>> {newPathStr}";
                
                GD.Print(log);
                AddToHistory(newPathStr);
            }

            // 5. EXIT old branch
            for (int i = _currentPath.Count - 1; i >= commonAncestorIndex; i--)
            {
                _currentPath[i].Exit();
            }

            // 6. Update Current
            CurrentState = newState;

            // 7. ENTER new branch
            for (int i = commonAncestorIndex; i < _newPath.Count; i++)
            {
                _newPath[i].Enter();
            }

            // Cleanup
            _currentPath.Clear();
            _newPath.Clear();
        }

        public void Update(double delta) => CurrentState?.Update(delta);
        public void PhysicsUpdate(double delta) => CurrentState?.PhysicsUpdate(delta);
        public bool HandleEvent(ActionEvent evt) => CurrentState?.HandleEvent(evt) ?? false;
        public LocomotionInstruction GetInstruction() => CurrentState?.GetLocomotionInstruction() ?? new LocomotionInstruction(0);

        // --- DEBUG API ---

        /// <summary>
        /// Returns a string like "Grounded -> Walk"
        /// </summary>
        public string GetCurrentPathString()
        {
            FillPathToRoot(CurrentState, _currentPath);
            string result = FormatPathString(_currentPath);
            _currentPath.Clear();
            return result;
        }

        /// <summary>
        /// Returns the recent history log joined by newlines
        /// </summary>
        public string GetHistoryString()
        {
            return string.Join("\n", _history);
        }

        // --- INTERNAL HELPERS ---

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
            outList.Reverse(); // [Root, Child, Leaf]
        }

        private string FormatPathString(List<HFSMState<T>> path)
        {
            if (path.Count == 0) return "None";
            
            // Using StringBuilder to minimize garbage during string concatenation
            var sb = new StringBuilder();
            for (int i = 0; i < path.Count; i++)
            {
                // Uses state.ToString() so you can override it in state classes for cleaner names
                sb.Append(path[i].ToString()); 
                if (i < path.Count - 1) sb.Append(" -> ");
            }
            return sb.ToString();
        }

        private void AddToHistory(string pathStr)
        {
            _history.AddFirst(pathStr);
            if (_history.Count > HISTORY_LIMIT)
            {
                _history.RemoveLast();
            }
        }
    }
}