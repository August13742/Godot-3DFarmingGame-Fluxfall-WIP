#nullable enable
using Godot;
using System.Collections.Generic;

public readonly record struct ActionEvent
{
    public enum ActionType { Jump, Attack, Dash, UseItem }
    
    public readonly ActionType Type;
    public readonly object? Payload; 

    public ActionEvent(ActionType type, object? payload = null)
    {
        Type = type;
        Payload = payload;
    }
}

public class ControlInterface
{
    public Vector3 MovementIntent { get; set; } = Vector3.Zero;
    public Vector3 AimIntent { get; set; } = Vector3.Zero;
    
    public bool IsSprintHeld { get; set; }
    public bool IsDefendHeld { get; set; }

    // or try implement CircualrBuffer
    private readonly Queue<ActionEvent> _eventQueue = new();

    public void QueueEvent(ActionEvent evt) => _eventQueue.Enqueue(evt);

    public bool TryDequeueEvent(out ActionEvent evt)
    {
        return _eventQueue.TryDequeue(out evt);
    }
    
    public bool HasEvents => _eventQueue.Count > 0;
}
