using Godot;
namespace CharacterControl
{
    public class AnimationArbiter
    {
        private readonly AnimationPlayer _animPlayer;
        private struct AnimationRequest
        {
            public StringName AnimationName;
            public float Speed;
            public bool IsSticky;
            public bool IsActive; //nullable flag for struct
        }
        private readonly AnimationRequest[] _requests = new AnimationRequest[AnimationChannel.Count];
        // State Tracking
        private int _currentChannel = -1;
        private StringName _currentAnim = null;
        private bool _isCurrentSticky = false;

        public AnimationArbiter(AnimationPlayer player)
        {
            _animPlayer = player;
            _animPlayer.AnimationFinished += OnAnimationFinished;
        }
        public void Request(int channel, StringName anim, float speed = 1.0f, bool sticky = false)
        {
            if (channel < 0 || channel >= AnimationChannel.Count) return;
            
            _requests[channel] = new AnimationRequest 
            { 
                AnimationName = anim, 
                Speed = speed, 
                IsSticky = sticky, 
                IsActive = true 
            };
        }
        public void ClearChannel(int channel)
        {
            if (channel >= 0 && channel < AnimationChannel.Count)
                _requests[channel].IsActive = false;
        }
        public void Update()
        {
            // 1. Find the highest priority ACTIVE request
            int bestChannel = -1;

            // Iterate backwards (Higher index = Higher priority)
            for (int i = AnimationChannel.Count - 1; i >= 0; i--)
            {
                if (_requests[i].IsActive)
                {
                    bestChannel = i;
                    break;
                }
            }

            // 2. Resolve Sticky Logic
            // If currently playing a sticky animation, only switch if:
            // A) The sticky animation finished (handled in event)
            // B) The new request is HIGHER priority than the sticky one
            
            if (_isCurrentSticky)
            {
                if (bestChannel <= _currentChannel) return; // Can't downgrade or interrupt equal
            }

            // 3. Apply Change
            if (bestChannel != -1)
            {
                var req = _requests[bestChannel];
                
                // Optimisation: Don't restart same animation unless specifically needed (looping?)
                if (_currentChannel != bestChannel || _currentAnim != req.AnimationName)
                {
                    _currentChannel = bestChannel;
                    _currentAnim = req.AnimationName;
                    _isCurrentSticky = req.IsSticky;
                    
                    if (_animPlayer.HasAnimation(req.AnimationName))
                    {
                        _animPlayer.Play(req.AnimationName, -1, req.Speed);
                    }
                }
            }
        }
        private void OnAnimationFinished(StringName animName)
        {
            // If the sticky animation finished, release the lock
            if (_isCurrentSticky && animName == _currentAnim)
            {
                _isCurrentSticky = false;
                // clear the request so we fall back to lower layers
                ClearChannel(_currentChannel);
                // Force an update immediately so we don't wait a frame
                Update();
            }
        }
    }
}