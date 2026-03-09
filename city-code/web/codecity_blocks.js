// ==============================
// CODECITY CUSTOM BLOCK DEFINITIONS
// ==============================

// --- City Blocks ---

Blockly.Blocks['place_building'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('place')
        .appendField(new Blockly.FieldDropdown([
          ['house', 'house'],
          ['shop', 'shop'],
          ['park', 'park'],
          ['tree', 'tree']
        ]), 'BUILDING_TYPE')
        .appendField('at x:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'X')
        .appendField('y:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'Y');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('city_blocks');
    this.setTooltip('Place a building on the city grid');
  }
};

Blockly.Blocks['remove_building'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('remove building at x:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'X')
        .appendField('y:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'Y');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('city_blocks');
    this.setTooltip('Remove a building from the grid');
  }
};

Blockly.Blocks['upgrade_building'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('upgrade building at x:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'X')
        .appendField('y:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'Y');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('city_blocks');
    this.setTooltip('Upgrade a building on the grid');
  }
};

// --- Road Blocks ---

Blockly.Blocks['place_road'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('place road at x:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'X')
        .appendField('y:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'Y');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('road_blocks');
    this.setTooltip('Place a road tile');
  }
};

Blockly.Blocks['set_tile'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('set tile')
        .appendField(new Blockly.FieldDropdown([
          ['road', 'road'],
          ['grass', 'grass']
        ]), 'TILE_TYPE')
        .appendField('at x:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'X')
        .appendField('y:')
        .appendField(new Blockly.FieldNumber(0, 0, 19, 1), 'Y');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('road_blocks');
    this.setTooltip('Set a tile type on the grid');
  }
};

// --- Resource Blocks ---

Blockly.Blocks['add_resource'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('add')
        .appendField(new Blockly.FieldNumber(10, 0), 'AMOUNT')
        .appendField(new Blockly.FieldDropdown([
          ['gold', 'gold'],
          ['wood', 'wood'],
          ['stone', 'stone'],
          ['food', 'food']
        ]), 'RESOURCE_TYPE');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('resource_blocks');
    this.setTooltip('Add resources to the city');
  }
};

Blockly.Blocks['has_resource'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('has')
        .appendField(new Blockly.FieldNumber(10, 0), 'AMOUNT')
        .appendField(new Blockly.FieldDropdown([
          ['gold', 'gold'],
          ['wood', 'wood'],
          ['stone', 'stone'],
          ['food', 'food']
        ]), 'RESOURCE_TYPE');
    this.setOutput(true, 'Boolean');
    this.setStyle('resource_blocks');
    this.setTooltip('Check if the city has enough of a resource');
  }
};

Blockly.Blocks['get_resource'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('get')
        .appendField(new Blockly.FieldDropdown([
          ['gold', 'gold'],
          ['wood', 'wood'],
          ['stone', 'stone'],
          ['food', 'food']
        ]), 'RESOURCE_TYPE');
    this.setOutput(true, 'Number');
    this.setStyle('resource_blocks');
    this.setTooltip('Get the current amount of a resource');
  }
};

// --- People Blocks ---

Blockly.Blocks['change_population'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('change population by')
        .appendField(new Blockly.FieldNumber(1, -100, 100, 1), 'AMOUNT');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('people_blocks');
    this.setTooltip('Increase or decrease the population');
  }
};

Blockly.Blocks['change_happiness'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('change happiness by')
        .appendField(new Blockly.FieldNumber(1, -100, 100, 1), 'AMOUNT');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('people_blocks');
    this.setTooltip('Increase or decrease happiness');
  }
};

Blockly.Blocks['get_city_stat'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('get')
        .appendField(new Blockly.FieldDropdown([
          ['population', 'population'],
          ['happiness', 'happiness']
        ]), 'STAT');
    this.setOutput(true, 'Number');
    this.setStyle('people_blocks');
    this.setTooltip('Get the current value of a city stat');
  }
};

// --- Event Blocks ---

Blockly.Blocks['when_city_starts'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('when city starts');
    this.appendStatementInput('DO');
    this.setStyle('event_blocks');
    this.setTooltip('Run code when the city starts');
  }
};

Blockly.Blocks['when_day_changes'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('when a new day starts');
    this.appendStatementInput('DO');
    this.setStyle('event_blocks');
    this.setTooltip('Run code when a new day begins');
  }
};

Blockly.Blocks['show_message'] = {
  init: function() {
    this.appendDummyInput()
        .appendField('show message')
        .appendField(new Blockly.FieldTextInput('Hello!'), 'MESSAGE');
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setStyle('event_blocks');
    this.setTooltip('Show a message to the player');
  }
};


// ==============================
// CODE GENERATORS
// ==============================

// Use javascript generator (Blockly.JavaScript for older versions)
var generator = Blockly.JavaScript;

generator.forBlock['place_building'] = function(block) {
  var type = block.getFieldValue('BUILDING_TYPE');
  var x = block.getFieldValue('X');
  var y = block.getFieldValue('Y');
  return 'place_building("' + type + '", ' + x + ', ' + y + ')\n';
};

generator.forBlock['remove_building'] = function(block) {
  var x = block.getFieldValue('X');
  var y = block.getFieldValue('Y');
  return 'remove_building(' + x + ', ' + y + ')\n';
};

generator.forBlock['upgrade_building'] = function(block) {
  var x = block.getFieldValue('X');
  var y = block.getFieldValue('Y');
  return 'upgrade_building(' + x + ', ' + y + ')\n';
};

generator.forBlock['place_road'] = function(block) {
  var x = block.getFieldValue('X');
  var y = block.getFieldValue('Y');
  return 'place_road(' + x + ', ' + y + ')\n';
};

generator.forBlock['set_tile'] = function(block) {
  var type = block.getFieldValue('TILE_TYPE');
  var x = block.getFieldValue('X');
  var y = block.getFieldValue('Y');
  return 'set_tile("' + type + '", ' + x + ', ' + y + ')\n';
};

generator.forBlock['add_resource'] = function(block) {
  var amount = block.getFieldValue('AMOUNT');
  var type = block.getFieldValue('RESOURCE_TYPE');
  return 'add_resource("' + type + '", ' + amount + ')\n';
};

generator.forBlock['has_resource'] = function(block) {
  var amount = block.getFieldValue('AMOUNT');
  var type = block.getFieldValue('RESOURCE_TYPE');
  return ['has_resource("' + type + '", ' + amount + ')', Blockly.JavaScript.ORDER_FUNCTION_CALL];
};

generator.forBlock['get_resource'] = function(block) {
  var type = block.getFieldValue('RESOURCE_TYPE');
  return ['get_resource("' + type + '")', Blockly.JavaScript.ORDER_FUNCTION_CALL];
};

generator.forBlock['change_population'] = function(block) {
  var amount = block.getFieldValue('AMOUNT');
  return 'change_population(' + amount + ')\n';
};

generator.forBlock['change_happiness'] = function(block) {
  var amount = block.getFieldValue('AMOUNT');
  return 'change_happiness(' + amount + ')\n';
};

generator.forBlock['get_city_stat'] = function(block) {
  var stat = block.getFieldValue('STAT');
  return ['get_city_stat("' + stat + '")', Blockly.JavaScript.ORDER_FUNCTION_CALL];
};

generator.forBlock['when_city_starts'] = function(block) {
  var statements = Blockly.JavaScript.statementToCode(block, 'DO');
  return '-- when city starts\n' + statements;
};

generator.forBlock['when_day_changes'] = function(block) {
  var statements = Blockly.JavaScript.statementToCode(block, 'DO');
  return '-- when day changes\n' + statements;
};

generator.forBlock['show_message'] = function(block) {
  var msg = block.getFieldValue('MESSAGE');
  return 'print("' + msg + '")\n';
};


// ==============================
// TOOLBOX XML
// ==============================

window.CODECITY_TOOLBOX_XML = `
<xml id="toolbox">
  <category name="City" colour="#7CCB92" css-class="cat-city">
    <block type="place_building">
      <field name="BUILDING_TYPE">house</field>
      <field name="X">0</field>
      <field name="Y">0</field>
    </block>
    <block type="remove_building"></block>
    <block type="upgrade_building"></block>
  </category>
  <category name="Roads" colour="#D9B26F">
    <block type="place_road"></block>
    <block type="set_tile"></block>
  </category>
  <category name="Resources" colour="#6FA8DC">
    <block type="add_resource"></block>
    <block type="has_resource"></block>
    <block type="get_resource"></block>
  </category>
  <category name="People" colour="#F4A261">
    <block type="change_population"></block>
    <block type="change_happiness"></block>
    <block type="get_city_stat"></block>
  </category>
  <category name="Events" colour="#C084D4">
    <block type="when_city_starts"></block>
    <block type="when_day_changes"></block>
    <block type="show_message"></block>
  </category>
  <sep></sep>
  <category name="Logic" colour="#8D99AE">
    <block type="controls_if"></block>
    <block type="logic_compare"></block>
    <block type="logic_boolean"></block>
  </category>
  <category name="Loops" colour="#8D99AE">
    <block type="controls_repeat_ext">
      <value name="TIMES">
        <shadow type="math_number"><field name="NUM">3</field></shadow>
      </value>
    </block>
  </category>
  <category name="Math" colour="#8D99AE">
    <block type="math_number"><field name="NUM">0</field></block>
    <block type="math_arithmetic"></block>
  </category>
  <category name="Variables" custom="VARIABLE" colour="#B56576"></category>
  <category name="Functions" custom="PROCEDURE" colour="#5C7AEA"></category>
</xml>
`;
