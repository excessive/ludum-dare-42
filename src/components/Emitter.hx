package components;

typedef ParticleData = {}

typedef Emitter = {
	/** emitting or not **/
	enabled: Bool,
	/** emitter lifetime **/
	lifetime: Float,
	/** particles/s **/
	emission_rate: Float,
	/** particle min lifetime **/
	emission_life_min: Float,
	/** particle max lifetime **/
	emission_life_max: Float,
	/** storage **/
	particles: Array<ParticleData>
}
