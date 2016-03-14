--[[This code specify the model for MNIST dataset. This model uses the vanila BatchNormalization algorithm.
In this file we also secify the Glorot learning parameter and which of the learnable parameter we clip ]]
require 'cunn'
require 'cudnn'
require 'nn'
require './BinaryLinear.lua'
require './BinarizedNeurons'
local model = nn.Sequential()
local numHid =2048
-- Convolution Layers
model:add(nn.View(-1,784))

model:add(BinaryLinear(784,numHid))
model:add(nn.BatchNormalization(numHid))
model:add(nn.HardTanh())
model:add(BinarizedNeurons(opt.stcNeurons))
model:add(BinaryLinear(numHid,numHid,opt.stcWeights))
model:add(nn.BatchNormalization(numHid))
model:add(nn.HardTanh())
model:add(BinarizedNeurons(opt.stcNeurons))
model:add(BinaryLinear(numHid,numHid,opt.stcWeights))
model:add(nn.BatchNormalization(numHid))
model:add(nn.HardTanh())
model:add(BinarizedNeurons(opt.stcNeurons))
model:add(BinaryLinear(numHid,10,opt.stcWeights))
model:add(nn.BatchNormalization(10))



local dE, param = model:getParameters()
local weight_size = dE:size(1)
local learningRates = torch.Tensor(weight_size):fill(0)
local clipvector = torch.Tensor(weight_size):fill(0)

local counter = 0
for i, layer in ipairs(model.modules) do
   if layer.__typename == 'BinaryLinear' then
      local weight_size = layer.weight:size(1)*layer.weight:size(2)
      local size_w=layer.weight:size();   GLR=1/torch.sqrt(1.5/(size_w[1]+size_w[2]))
      learningRates[{{counter+1, counter+weight_size}}]:fill(GLR)
      clipvector[{{counter+1, counter+weight_size}}]:fill(1)
      counter = counter+weight_size
      local bias_size = layer.bias:size(1)
      learningRates[{{counter+1, counter+bias_size}}]:fill(GLR)
      clipvector[{{counter+1, counter+bias_size}}]:fill(0)
      counter = counter+bias_size
    elseif layer.__typename == 'nn.BatchNormalization' then
      local weight_size = layer.weight:size(1)
      local size_w=layer.weight:size();   GLR=1/torch.sqrt(1.5/(size_w[1]))
      learningRates[{{counter+1, counter+weight_size}}]:fill(GLR)
      clipvector[{{counter+1, counter+weight_size}}]:fill(0)
      counter = counter+weight_size
      local bias_size = layer.bias:size(1)
      learningRates[{{counter+1, counter+bias_size}}]:fill(1)
      clipvector[{{counter+1, counter+bias_size}}]:fill(0)
      counter = counter+bias_size
  end
end
print(learningRates:eq(0):sum())
print(learningRates:ne(0):sum())
print(counter)

return {
   model = model,
   lrs = learningRates,
   clipV =clipvector,
}
