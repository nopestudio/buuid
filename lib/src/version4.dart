


// func NewRandom() (UUID, error) {
// 	if !poolEnabled {
// 		return NewRandomFromReader(rander)
// 	}
// 	return newRandomFromPool()
// }

// // NewRandomFromReader returns a UUID based on bytes read from a given io.Reader.
// func NewRandomFromReader(r io.Reader) (UUID, error) {
// 	var uuid UUID
// 	_, err := io.ReadFull(r, uuid[:])
// 	if err != nil {
// 		return Nil, err
// 	}
// 	uuid[6] = (uuid[6] & 0x0f) | 0x40 // Version 4
// 	uuid[8] = (uuid[8] & 0x3f) | 0x80 // Variant is 10
// 	return uuid, nil
// }

// func newRandomFromPool() (UUID, error) {
// 	var uuid UUID
// 	poolMu.Lock()
// 	if poolPos == randPoolSize {
// 		_, err := io.ReadFull(rander, pool[:])
// 		if err != nil {
// 			poolMu.Unlock()
// 			return Nil, err
// 		}
// 		poolPos = 0
// 	}
// 	copy(uuid[:], pool[poolPos:(poolPos+16)])
// 	poolPos += 16
// 	poolMu.Unlock()

// 	uuid[6] = (uuid[6] & 0x0f) | 0x40 // Version 4
// 	uuid[8] = (uuid[8] & 0x3f) | 0x80 // Variant is 10
// 	return uuid, nil
// }