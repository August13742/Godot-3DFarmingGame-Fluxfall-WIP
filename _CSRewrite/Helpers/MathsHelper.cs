using Godot;

    public static class MathsUtility
    {
        public static Vector3 ExpDecay(Vector3 current, Vector3 target, float decay, float dt)
        {
            if (decay <= 0.0001f) return target;
            return target + (current - target) * Mathf.Exp(-dt / decay);
        }

        public static float ExpDecay(float current, float target, float decay, float dt)
        {
            if (decay <= 0.0001f) return target;
            return target + (current - target) * Mathf.Exp(-dt / decay);
        }
    }
