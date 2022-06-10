declare function afterAll(callback: () -> ()): ()
declare function afterEach(callback: () -> ()): ()

declare function beforeAll(callback: () -> ()): ()
declare function beforeEach(callback: () -> ()): ()

declare function describe(phrase: string, callback: () -> ()): ()
declare function describeFOCUS(phrase: string, callback: () -> ()): ()
declare function fdescribe(phrase: string, callback: () -> ()): ()
declare function describeSKIP(phrase: string, callback: () -> ()): ()
declare function xdescribe(phrase: string, callback: () -> ()): ()

declare function expect(value: any): any

declare function FIXME(optionalMessage: string?): ()
declare function FOCUS(): ()
declare function SKIP(): ()

declare function it(phrase: string, callback: () -> ()): ()
declare function itFOCUS(phrase: string, callback: () -> ()): ()
declare function fit(phrase: string, callback: () -> ()): ()
declare function itSKIP(phrase: string, callback: () -> ()): ()
declare function xit(phrase: string, callback: () -> ()): ()
declare function itFIXME(phrase: string, callback: () -> ()): ()
