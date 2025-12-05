using Godot;

namespace CharacterControl
{
    public partial class HFSMCharacter3D:CharacterBody3D
    {
        [Export]public float Gravity{get;private set;} = 9.8f;
    }
}