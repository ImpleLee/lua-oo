local class = require 'class'

local animal = class {
  __init = function(self, name, sound)
    self.name = name
    self.sound = sound or '...'
  end,
  speak = function(self) print(self.name .. ' says ' .. self.sound) end
}

local alice = animal('Alice')
alice:speak()

local dog = class:is(animal) {
  __init = function(self, name) self.__parents[1].__init(self, name, 'woof') end,
  bark = function(self) print(self.name .. ' barks!') end
}

local bob = dog('Bob')
bob:speak()
bob:bark()

local O = class {name = 'O'}

local A = class:is(O) {name = 'A'}
local B = class:is(O) {name = 'B'}
local C = class:is(O) {name = 'C'}
local D = class:is(O) {name = 'D'}
local E = class:is(O) {name = 'E'}

local K1 = class:is(A, B, C) {name = 'K1'}
local K2 = class:is(D, B, E) {name = 'K2'}
local K3 = class:is(D, A) {name = 'K3'}

local Z = class:is(K1, K2, K3) {name = 'Z'}

for i, name in Z().__resolve('name') do print(i, name) end
-- print Z K1 K2 K3 D A B C E O

local A = class {name = 'A'}
local B = class {name = 'B'}
local C = class:is(A) {name = 'C'}
local D = class:is(B) {name = 'D'}
local E = class:is(C, D) {name = 'E'}
for i, name in E().__resolve('name') do print(i, name) end
-- print E C D A B
