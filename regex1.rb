require "./parseExp"

if ARGV.length < 2
  puts "Please follow the correct arguments, like expressions.text targets.txt"
  return "-1"
end

oneReg = RegEx.new

if ARGV[0] == 'single'
  if  ARGV.length <3
    puts "Please follow the correct arguments, like single “a|b” b"
    return "-1"
  else
    #puts ARGV

  end
  result = oneReg.parseReg(ARGV[1], ARGV[2])
  puts result
  #oneReg.matchTarget(ARGV[2])
else
  fileRead(oneReg)
end

def fileRead(oneReg)
  expressions = File.read("./expressions.txt").split
  targets = File.read("./targets.txt").split
  origin_expected = File.read("./expected.txt").split
  for i in 0..expressions.length do
    initResult = oneReg.initParseExp(expressions[i])
    if initResult == 0
      result = oneReg.parseReg(expressions[i], targets[i])
    else
      result = initResult
    end
    strExpected = `${getResultText(result)} ${expressions[i]} with ${targets[i]}`
    exception = []
    expected = []
    if strExpected != origin_expected[i]
      exception.push(`${i+1} ${origin_expected[i]} but my is ${strExpected}`)
    end
    expected.push(strExpected)
  end
    if i === expressions.length
      File.write("./bruce_expected.txt", expected.join("\n"), mode: "a")
      File.write("./exceptions.txt", exception.join("\n"), mode: "a")
  end
end




